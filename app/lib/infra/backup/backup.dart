/// 프로젝트 백업 만들기·가져오기 (PRD FR-09, Spec §11).
///
/// 형식: ZIP(stored·deflate) 안에 `manifest.json`, `base/(역할 키 UTF-8 16진).hws`,
/// `custom/(코드포인트 16진 5자리)/(seq).hws|.hwo`, `custom/index.json`, `memos.json`.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/decode_error.dart';
import '../../domain/font/naming.dart';
import '../../domain/glyph/hwo1.dart';
import '../../domain/glyph/latin_set.dart';
import '../../domain/hangul/base_set.dart';
import '../../domain/hangul/hangul.dart';
import '../../domain/ink/hws1.dart';
import '../db/database.dart';
import '../db/memo_dao.dart';
import '../db/project_dao.dart';

const backupFormat = 'hwaeaek-backup';
const backupFormatVersion = 1;
const backupExtension = 'hwaeaek';

enum BackupErrorCode {
  tooLarge('백업 파일이 너무 큽니다.'),
  notBackup('회애액 백업 파일이 아닙니다.'),
  newerVersion('더 새로운 버전의 앱에서 만든 백업입니다. 앱을 업데이트해 주세요.'),
  corrupt('백업 파일이 손상되었습니다.'),
  storage('저장 공간이 부족합니다.');

  const BackupErrorCode(this.message);

  final String message;
}

class BackupError implements Exception {
  const BackupError(this.code, [this.detail = '']);

  final BackupErrorCode code;
  final String detail;

  @override
  String toString() => 'BackupError(${code.name}): $detail';
}

// ---- 이름 규칙과 상한 (Spec §11.1, §11.3) ----

final _manifest = RegExp(r'^manifest\.json$');
final _base = RegExp(r'^base/([0-9A-F]{2,64})\.hws$');
final _custom = RegExp(r'^custom/([0-9A-F]{5})/([1-9][0-9]{0,8})\.(hws|hwo)$');
final _index = RegExp(r'^custom/index\.json$');
final _memos = RegExp(r'^memos\.json$');

const _maxCentralDirectory = 64 << 20;
const _maxGlyphEntry = 512 << 10;
const _maxManifest = 1 << 20;
const _maxJson = 64 << 20;
const _maxRatio = 200;

int _capFor(String name) {
  if (_manifest.hasMatch(name)) return _maxManifest;
  if (_index.hasMatch(name) || _memos.hasMatch(name)) return _maxJson;
  return _maxGlyphEntry;
}

bool _known(String name) =>
    _manifest.hasMatch(name) ||
    _base.hasMatch(name) ||
    _custom.hasMatch(name) ||
    _index.hasMatch(name) ||
    _memos.hasMatch(name);

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();

List<int> _unhex(String s) => [
  for (var i = 0; i < s.length; i += 2)
    int.parse(s.substring(i, i + 2), radix: 16),
];

String _cpHex(int cp) => cp.toRadixString(16).toUpperCase().padLeft(5, '0');

// ---- 만들기 ----

/// 백업 파일 이름: 프로젝트 이름에서 파일 이름에 못 쓰는 문자를 `_`로 바꾸고 64자로 자른다.
String backupFileName(String projectName) {
  var s = projectName.replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1F]'), '_').trim();
  if (s.length > 64) s = s.substring(0, 64);
  return '${s.isEmpty ? 'hwaeaek-backup' : s}.$backupExtension';
}

/// 읽기 트랜잭션 하나로 프로젝트를 읽어 [dir]에 백업을 만든다. 만든 파일을
/// 가져오기와 같은 검사기로 검사한 뒤 돌려준다(Spec §11.2).
Future<File> writeBackup(
  AppDatabase db,
  String projectId,
  Directory dir, {
  required String appVersion,
}) async {
  final data = await db.transaction(() async {
    final project = await (db.select(
      db.projects,
    )..where((p) => p.id.equals(projectId))).getSingle();
    final base = await (db.select(
      db.baseGlyphs,
    )..where((b) => b.projectId.equals(projectId))).get();
    final revisions =
        await (db.select(db.customRevisions)
              ..where((r) => r.projectId.equals(projectId))
              ..orderBy([
                (r) => OrderingTerm.asc(r.createdAt),
                (r) => OrderingTerm.asc(r.id),
              ]))
            .get();
    final customs = await (db.select(
      db.customGlyphs,
    )..where((c) => c.projectId.equals(projectId))).get();
    final memos =
        await (db.select(db.memos)
              ..where((m) => m.projectId.equals(projectId))
              ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
            .get();
    return (project, base, revisions, customs, memos);
  });
  final (project, base, revisions, customs, memos) = data;

  final file = File('${dir.path}/${backupFileName(project.name)}');
  final part = File('${file.path}.part');
  final zip = ZipFileEncoder()..create(part.path);
  void add(String name, List<int> bytes) =>
      zip.addArchiveFile(ArchiveFile.bytes(name, bytes));

  add(
    'manifest.json',
    utf8.encode(
      jsonEncode({
        'format': backupFormat,
        'formatVersion': backupFormatVersion,
        'schemaVersion': db.schemaVersion,
        'ruleVersion': project.ruleVersion,
        'baseSetVersion': project.baseSetVersion,
        'appVersion': appVersion,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'project': {
          'name': project.name,
          'memoUnlockedAt': project.memoUnlockedAt,
          'font': {
            'familyName': project.fontFamilyName,
            'asciiFamilyName': project.fontAsciiName,
            'styleName': project.fontStyleName,
            'versionMinor': project.fontVersionMinor,
            'license': project.fontLicense,
          },
          'baseGlyphs': {
            for (final b in base)
              _hex(utf8.encode(b.roleKey)): {'updatedAt': b.updatedAt},
          },
        },
      }),
    ),
  );
  for (final b in base) {
    add('base/${_hex(utf8.encode(b.roleKey))}.hws', b.strokes);
  }
  final index = <String, Object>{};
  final byCp = <int, List<CustomRevisionRow>>{};
  for (final r in revisions) {
    (byCp[r.codePoint] ??= []).add(r);
  }
  for (final c in customs) {
    final list = byCp[c.codePoint] ?? const [];
    final hex = _cpHex(c.codePoint);
    for (final (i, r) in list.indexed) {
      add('custom/$hex/${i + 1}.hws', r.strokes);
      add('custom/$hex/${i + 1}.hwo', r.outline);
    }
    index[hex] = {
      'selection': c.selection,
      'current': list.indexWhere((r) => r.id == c.currentRevisionId) + 1,
      'revisions': [
        for (final (i, r) in list.indexed)
          {'seq': i + 1, 'createdAt': r.createdAt, 'pen': jsonDecode(r.pen)},
      ],
    };
  }
  add('custom/index.json', utf8.encode(jsonEncode(index)));
  add(
    'memos.json',
    utf8.encode(
      jsonEncode([
        for (final m in memos)
          {'text': m.text$, 'createdAt': m.createdAt, 'updatedAt': m.updatedAt},
      ]),
    ),
  );
  await zip.close();

  try {
    await inspectBackup(part);
  } catch (_) {
    await part.delete();
    rethrow;
  }
  if (file.existsSync()) await file.delete();
  return part.rename(file.path);
}

// ---- 가져오기 ----

/// 검사만 한다(DB에 쓰지 않음). 만들기 후 자체 검사에 쓴다.
Future<void> inspectBackup(File file) async {
  final reader = await _BackupReader.open(file);
  try {
    reader.validateAll();
  } finally {
    await reader.close();
  }
}

/// 백업을 새 프로젝트로 가져온다(Spec §11.3). 실패하면 아무것도 쓰지 않는다.
Future<String> importBackup(AppDatabase db, File file, {Clock? clock}) async {
  final reader = await _BackupReader.open(file);
  final now = (clock ?? systemClock)();
  try {
    final plan = reader.validateAll();
    final id = const Uuid().v4();
    try {
      await db.transaction(() async {
        final m = plan.manifest;
        final font = m['font'] as Map<String, Object?>;
        await db
            .into(db.projects)
            .insert(
              ProjectsCompanion.insert(
                id: id,
                name: m['name']! as String,
                createdAt: now,
                updatedAt: now,
                baseSetVersion: plan.baseSetVersion,
                ruleVersion: plan.ruleVersion,
                memoUnlockedAt: Value(m['memoUnlockedAt'] as int?),
                fontFamilyName: font['familyName']! as String,
                fontAsciiName: font['asciiFamilyName']! as String,
                fontStyleName: Value(font['styleName']! as String),
                fontVersionMinor: Value(font['versionMinor']! as int),
                fontLicense: Value(font['license']! as String),
              ),
            );
        for (final b in plan.base) {
          await db
              .into(db.baseGlyphs)
              .insert(
                BaseGlyphsCompanion.insert(
                  projectId: id,
                  roleKey: b.roleKey,
                  strokes: b.strokes,
                  updatedAt: b.updatedAt,
                ),
              );
        }
        for (final c in plan.customs) {
          int? currentId;
          for (final r in c.revisions) {
            final rid = await db
                .into(db.customRevisions)
                .insert(
                  CustomRevisionsCompanion.insert(
                    projectId: id,
                    codePoint: c.codePoint,
                    strokes: r.strokes,
                    outline: r.outline,
                    pen: r.pen,
                    createdAt: r.createdAt,
                  ),
                );
            if (r.seq == c.current) currentId = rid;
          }
          await db
              .into(db.customGlyphs)
              .insert(
                CustomGlyphsCompanion.insert(
                  projectId: id,
                  codePoint: c.codePoint,
                  selection: c.selection,
                  currentRevisionId: currentId!,
                ),
              );
        }
        for (final memo in plan.memos) {
          await db
              .into(db.memos)
              .insert(
                MemosCompanion.insert(
                  id: const Uuid().v4(),
                  projectId: id,
                  text$: memo.text,
                  createdAt: memo.createdAt,
                  updatedAt: memo.updatedAt,
                ),
              );
        }
      });
    } on Object catch (e) {
      if (_isStorageFull(e)) throw const BackupError(BackupErrorCode.storage);
      rethrow;
    }
    return id;
  } finally {
    await reader.close();
  }
}

bool _isStorageFull(Object e) {
  final s = e.toString();
  return s.contains('SQLITE_FULL') ||
      s.contains('(13)') ||
      s.contains('code 13');
}

// ---- 검사 ----

class _BaseEntry {
  _BaseEntry(this.roleKey, this.strokes, this.updatedAt);

  final String roleKey;
  final Uint8List strokes;
  final int updatedAt;
}

class _RevisionEntry {
  _RevisionEntry(
    this.seq,
    this.strokes,
    this.outline,
    this.pen,
    this.createdAt,
  );

  final int seq;
  final Uint8List strokes;
  final Uint8List outline;
  final String pen;
  final int createdAt;
}

class _CustomEntry {
  _CustomEntry(this.codePoint, this.selection, this.current, this.revisions);

  final int codePoint;
  final String selection;
  final int current;
  final List<_RevisionEntry> revisions;
}

class _MemoEntry {
  _MemoEntry(this.text, this.createdAt, this.updatedAt);

  final String text;
  final int createdAt;
  final int updatedAt;
}

class _Plan {
  _Plan(
    this.manifest,
    this.baseSetVersion,
    this.ruleVersion,
    this.base,
    this.customs,
    this.memos,
  );

  final Map<String, Object?> manifest;
  final int baseSetVersion;
  final int ruleVersion;
  final List<_BaseEntry> base;
  final List<_CustomEntry> customs;
  final List<_MemoEntry> memos;
}

Never _corrupt(String detail) =>
    throw BackupError(BackupErrorCode.corrupt, detail);

T _field<T>(Map<String, Object?> m, String key) {
  final v = m[key];
  if (v is! T) _corrupt('field $key');
  return v;
}

class _BackupReader {
  _BackupReader._(this._input, this._entries);

  final InputFileStream _input;
  final Map<String, ArchiveFile> _entries;

  static Future<_BackupReader> open(File file) async {
    final InputFileStream input;
    try {
      input = InputFileStream(file.path);
    } catch (_) {
      throw const BackupError(BackupErrorCode.notBackup);
    }
    try {
      // 1) 중앙 디렉터리 헤더만 먼저 검사한다(내용은 아직 풀지 않음).
      final dir = ZipDirectory()..read(input);
      if (dir.centralDirectorySize > _maxCentralDirectory) {
        throw const BackupError(BackupErrorCode.tooLarge, 'central directory');
      }
      final names = <String>{};
      for (final h in dir.fileHeaders) {
        final name = h.filename;
        if (!names.add(name)) _corrupt('duplicate $name');
        if (!_known(name)) _corrupt('unknown entry $name');
        if (h.generalPurposeBitFlag & 0x1 != 0) _corrupt('encrypted $name');
        if (h.compressionMethod != 0 && h.compressionMethod != 8) {
          _corrupt('method $name');
        }
        final unixType = (h.externalFileAttributes >> 16) & 0xF000;
        if (unixType == 0xA000 || unixType == 0x4000) {
          _corrupt('link or dir $name');
        }
        if (h.uncompressedSize > _capFor(name)) {
          throw BackupError(BackupErrorCode.tooLarge, name);
        }
        if (h.compressedSize > 0 &&
            h.uncompressedSize / h.compressedSize > _maxRatio) {
          throw BackupError(BackupErrorCode.tooLarge, 'ratio $name');
        }
      }
      if (!names.contains('manifest.json')) {
        throw const BackupError(BackupErrorCode.notBackup, 'no manifest');
      }
      input.reset();
      final archive = ZipDecoder().decodeStream(input);
      return _BackupReader._(input, {for (final f in archive.files) f.name: f});
    } on BackupError {
      await input.close();
      rethrow;
    } catch (e) {
      await input.close();
      throw BackupError(BackupErrorCode.notBackup, '$e');
    }
  }

  Future<void> close() => _input.close();

  /// 항목 하나를 풀며 실제로 나온 바이트를 세어 상한을 넘는 순간 중단한다.
  Uint8List _read(String name) {
    final f = _entries[name] ?? _corrupt('missing $name');
    final cap = _capFor(name);
    final raw = f.rawContent;
    if (raw is! ZipFile) _corrupt('content $name');
    final compressed = raw.getStream(decompress: false).toUint8List();
    if (raw.compressionMethod == CompressionType.none) {
      if (compressed.length > cap) {
        throw BackupError(BackupErrorCode.tooLarge, name);
      }
      return compressed;
    }
    final filter = RawZLibFilter.inflateFilter(raw: true);
    final out = BytesBuilder(copy: false);
    const chunk = 64 << 10;
    for (var i = 0; i < compressed.length; i += chunk) {
      final end = i + chunk < compressed.length ? i + chunk : compressed.length;
      filter.process(compressed, i, end);
      for (List<int>? c; (c = filter.processed(flush: false)) != null;) {
        out.add(c!);
        if (out.length > cap) throw BackupError(BackupErrorCode.tooLarge, name);
      }
    }
    for (List<int>? c; (c = filter.processed(end: true)) != null;) {
      out.add(c!);
      if (out.length > cap) throw BackupError(BackupErrorCode.tooLarge, name);
    }
    final bytes = out.toBytes();
    if (bytes.length != raw.uncompressedSize) _corrupt('size $name');
    return bytes;
  }

  Object? _json(String name) {
    try {
      return jsonDecode(utf8.decode(_read(name)));
    } on BackupError {
      rethrow;
    } catch (_) {
      _corrupt('json $name');
    }
  }

  _Plan validateAll() {
    // manifest
    final manifest = _json('manifest.json');
    if (manifest is! Map<String, Object?> ||
        manifest['format'] != backupFormat) {
      throw const BackupError(BackupErrorCode.notBackup, 'format');
    }
    final formatVersion = _field<int>(manifest, 'formatVersion');
    final schemaVersion = _field<int>(manifest, 'schemaVersion');
    final baseSetVersion = _field<int>(manifest, 'baseSetVersion');
    final ruleVersion = _field<int>(manifest, 'ruleVersion');
    _field<String>(manifest, 'appVersion');
    _field<int>(manifest, 'createdAt');
    // ruleVersion은 거부 조건이 아니다(Spec §11.3).
    if (formatVersion > backupFormatVersion ||
        schemaVersion > 1 ||
        baseSetVersion > latestBaseSetVersion) {
      throw const BackupError(BackupErrorCode.newerVersion);
    }
    if (formatVersion < 1 || schemaVersion < 1 || baseSetVersion < 1) {
      _corrupt('version');
    }
    final project = _field<Map<String, Object?>>(manifest, 'project');
    _field<String>(project, 'name');
    if (project['memoUnlockedAt'] != null) {
      _field<int>(project, 'memoUnlockedAt');
    }
    final font = _field<Map<String, Object?>>(project, 'font');
    _field<String>(font, 'familyName');
    if (asciiFamilyNameError(_field<String>(font, 'asciiFamilyName')) != null) {
      _corrupt('ascii name');
    }
    _field<String>(font, 'styleName');
    final minor = _field<int>(font, 'versionMinor');
    if (minor < 0 || minor > 999) _corrupt('versionMinor');
    _field<String>(font, 'license');
    final baseMeta = _field<Map<String, Object?>>(project, 'baseGlyphs');

    // 기본 글리프
    final jamo = {
      for (var cp = compatJamoFirst; cp <= compatJamoLast; cp++)
        String.fromCharCode(cp),
      for (final cp in latinCodePoints) String.fromCharCode(cp),
    };
    final base = <_BaseEntry>[];
    final baseFiles = _entries.keys
        .map(_base.firstMatch)
        .whereType<RegExpMatch>()
        .toList();
    if (baseFiles.length != baseMeta.length) _corrupt('base count');
    for (final m in baseFiles) {
      final hex = m.group(1)!;
      final String key;
      try {
        key = utf8.decode(_unhex(hex));
      } catch (_) {
        _corrupt('base key');
      }
      if (!jamo.contains(key)) _corrupt('base key $key');
      final meta = baseMeta[hex];
      if (meta is! Map<String, Object?>) _corrupt('base meta $hex');
      final bytes = _read(m.group(0)!);
      _decodeStrokes(bytes);
      base.add(_BaseEntry(key, bytes, _field<int>(meta, 'updatedAt')));
    }

    // 커스텀
    final index = _entries.containsKey('custom/index.json')
        ? _json('custom/index.json')
        : <String, Object?>{};
    if (index is! Map<String, Object?>) _corrupt('index');
    final referenced = <String>{};
    final customs = <_CustomEntry>[];
    for (final MapEntry(:key, :value) in index.entries) {
      if (!RegExp(r'^[0-9A-F]{5}$').hasMatch(key)) _corrupt('index key $key');
      final cp = int.parse(key, radix: 16);
      if (!Syllable.isSyllable(cp)) _corrupt('code point $key');
      if (value is! Map<String, Object?>) _corrupt('index entry $key');
      final selection = _field<String>(value, 'selection');
      if (selection != 'generated' && selection != 'custom') {
        _corrupt('selection $key');
      }
      final current = _field<int>(value, 'current');
      final revs = _field<List<Object?>>(value, 'revisions');
      if (revs.isEmpty) _corrupt('no revisions $key');
      final entries = <_RevisionEntry>[];
      for (final (i, r) in revs.indexed) {
        if (r is! Map<String, Object?>) _corrupt('revision $key');
        final seq = _field<int>(r, 'seq');
        if (seq != i + 1) _corrupt('seq $key');
        final pen = _field<Map<String, Object?>>(r, 'pen');
        final hws = 'custom/$key/$seq.hws', hwo = 'custom/$key/$seq.hwo';
        referenced
          ..add(hws)
          ..add(hwo);
        final strokes = _read(hws);
        final outline = _read(hwo);
        _decodeStrokes(strokes);
        try {
          decodeHwo1(outline);
        } on DecodeError catch (e) {
          _corrupt('$hwo ${e.message}');
        }
        entries.add(
          _RevisionEntry(
            seq,
            strokes,
            outline,
            jsonEncode(pen),
            _field<int>(r, 'createdAt'),
          ),
        );
      }
      if (current < 1 || current > entries.length) _corrupt('current $key');
      customs.add(_CustomEntry(cp, selection, current, entries));
    }
    for (final name in _entries.keys.where(_custom.hasMatch)) {
      if (!referenced.contains(name)) _corrupt('unreferenced $name');
    }

    // 메모
    final memosJson = _entries.containsKey('memos.json')
        ? _json('memos.json')
        : <Object?>[];
    if (memosJson is! List<Object?>) _corrupt('memos');
    final memos = <_MemoEntry>[
      for (final m in memosJson)
        if (m is Map<String, Object?>)
          () {
            final text = _field<String>(m, 'text');
            if (text.length > maxMemoLength) _corrupt('memo length');
            return _MemoEntry(
              text,
              _field<int>(m, 'createdAt'),
              _field<int>(m, 'updatedAt'),
            );
          }()
        else
          _corrupt('memo'),
    ];

    return _Plan(project, baseSetVersion, ruleVersion, base, customs, memos);
  }

  void _decodeStrokes(Uint8List bytes) {
    try {
      decodeHws1(bytes);
    } on DecodeError catch (e) {
      _corrupt(e.message);
    }
  }
}
