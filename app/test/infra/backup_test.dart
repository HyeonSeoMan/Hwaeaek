import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/domain/ink/hws1.dart';
import 'package:hwaeaek/domain/ink/ink.dart';
import 'package:hwaeaek/infra/backup/backup.dart';
import 'package:hwaeaek/infra/db/database.dart';
import 'package:hwaeaek/infra/db/glyph_dao.dart';

import '../support/db.dart';

void main() {
  late TestDb t;
  late String p;
  late Directory dir;

  setUp(() async {
    t = TestDb.memory();
    p = await t.projectWithBaseGlyphs();
    dir = await Directory.systemTemp.createTemp('hwaeaek_backup');
  });
  tearDown(() => t.close());

  Future<File> backup() => writeBackup(t.db, p, dir, appVersion: '1.0.0+1');

  /// 정상 백업을 풀어 항목 맵(이름 → 바이트)을 [edit]로 고친 뒤 다시 묶는다.
  Future<File> tampered(void Function(Map<String, List<int>> entries) edit) async {
    final good = await backup();
    final entries = {
      for (final f in ZipDecoder().decodeBytes(await good.readAsBytes()).files)
        f.name: f.content.toList(),
    };
    edit(entries);
    final archive = Archive();
    for (final MapEntry(:key, :value) in entries.entries) {
      archive.addFile(ArchiveFile.bytes(key, value));
    }
    final f = File('${dir.path}/tampered.hwaeaek');
    await f.writeAsBytes(ZipEncoder().encode(archive));
    return f;
  }

  Map<String, Object?> manifestOf(Map<String, List<int>> a) =>
      jsonDecode(utf8.decode(a['manifest.json']!)) as Map<String, Object?>;

  Future<void> expectRejected(File f, BackupErrorCode code) async {
    final projects = await t.count('projects');
    await expectLater(
      importBackup(t.db, f),
      throwsA(isA<BackupError>().having((e) => e.code, 'code', code)),
    );
    expect(await t.count('projects'), projects, reason: '실패하면 아무것도 쓰지 않는다');
  }

  test('TS-17 백업 → 가져오기: 새 프로젝트로 같은 데이터가 복원된다', () async {
    final first = await t.saveCustom(p, kang);
    final second = await t.saveCustom(p, kang);
    await t.glyphs.revertToGenerated(p, kang); // 이력은 있으나 generated
    await t.saveCustom(p, gak);
    final memo = await t.memos.create(p);
    await t.memos.updateText(memo, '안녕 강');
    await t.projects.updateFontMetadata(p, familyName: '내 손글씨', asciiFamilyName: 'My Hand', license: 'OFL');
    await t.projects.commitFontVersion(p, 4);

    await t.glyphs.saveBaseGlyph(p, 'A', [
      const InkStroke([InkPoint(200, 0), InkPoint(400, 680), InkPoint(600, 0)]),
    ]);
    final file = await backup();
    expect(file.path, endsWith('.hwaeaek'));
    final id = await importBackup(t.db, file);
    expect(id, isNot(p));

    final a = await t.projects.get(p), b = await t.projects.get(id);
    expect(
      (b.name, b.fontFamilyName, b.fontAsciiName, b.fontLicense, b.fontVersionMinor, b.memoUnlockedAt),
      (a.name, a.fontFamilyName, a.fontAsciiName, a.fontLicense, a.fontVersionMinor, a.memoUnlockedAt),
    );
    expect(b.glyphRevision, 0);
    expect(await t.glyphs.baseGlyphs(id), hasLength(36)); // 35 + 영문 A

    final kangA = await t.glyphs.revisions(p, kang), kangB = await t.glyphs.revisions(id, kang);
    String key(CustomRevisionRow r) => '${r.createdAt}|${r.strokes}|${r.outline}|${r.pen}';
    expect(kangB.map(key), kangA.map(key));
    final state = await t.glyphs.customState(id, kang);
    expect(state!.selection, GlyphSelection.generated);
    expect(state.revisionId, kangB.last.id); // 두 번째 수정본이 현재
    expect(second.after.revisionId, kangA.last.id);
    expect(first.after.revisionId, kangA.first.id);
    expect((await t.glyphs.customState(id, gak))!.selection, GlyphSelection.custom);

    final memosB = await (t.db.select(t.db.memos)..where((m) => m.projectId.equals(id))).get();
    expect(memosB.single.text$, '안녕 강');
    expect(memosB.single.id, isNot(memo));
  });

  test('백업 파일 이름은 파일 이름에 못 쓰는 문자를 바꾼다', () {
    expect(backupFileName('내/손:글*씨'), '내_손_글_씨.hwaeaek');
    expect(backupFileName('   '), 'hwaeaek-backup.hwaeaek');
  });

  group('TS-18 손상·악성 백업 거부', () {
    test('ZIP이 아닌 파일', () async {
      final f = File('${dir.path}/x.hwaeaek')..writeAsStringSync('hello');
      await expectRejected(f, BackupErrorCode.notBackup);
    });

    test('manifest 없음', () async {
      final f = await tampered((a) => a.remove('manifest.json'));
      await expectRejected(f, BackupErrorCode.notBackup);
    });

    test('앱보다 새 버전', () async {
      final f = await tampered((a) {
        final m = manifestOf(a)..['formatVersion'] = 99;
        a['manifest.json'] = utf8.encode(jsonEncode(m));
      });
      await expectRejected(f, BackupErrorCode.newerVersion);
    });

    test('규칙 버전이 달라도 거부하지 않는다', () async {
      final f = await tampered((a) {
        final m = manifestOf(a)..['ruleVersion'] = 99;
        a['manifest.json'] = utf8.encode(jsonEncode(m));
      });
      expect(await importBackup(t.db, f), isNotEmpty);
    });

    test('경로 조작(..)과 모르는 항목', () async {
      for (final name in ['../evil.hws', '/abs.hws', 'base/../x.hws', 'extra.txt']) {
        final f = await tampered((a) => a[name] = [1, 2, 3]);
        await expectRejected(f, BackupErrorCode.corrupt);
      }
    });

    test('압축 폭탄: 압축률이 지나치게 높은 항목', () async {
      final f = await tampered(
        (a) => a['memos.json'] = Uint8List(32 << 20), // 0이 32MB → 압축률 수천
      );
      await expectRejected(f, BackupErrorCode.tooLarge);
    });

    test('항목 상한 초과', () async {
      final f = await tampered((a) {
        // 무작위에 가까운 바이트 600KB (압축률 낮음) → .hws 상한 512KB 초과
        final noise = Uint8List.fromList([for (var i = 0; i < 600 << 10; i++) (i * 2654435761) >> 13 & 0xFF]);
        a['base/E384B1.hws'] = noise;
      });
      await expectRejected(f, BackupErrorCode.tooLarge);
    });

    test('범위 밖 좌표의 획', () async {
      final f = await tampered((a) {
        final bad = encodeHws1([
          const InkStroke([InkPoint(0, 0), InkPoint(1, 1)]),
        ]);
        ByteData.sublistView(bad).setFloat32(6 + 4, 40000, Endian.little);
        a['base/E384B1.hws'] = bad;
      });
      await expectRejected(f, BackupErrorCode.corrupt);
    });

    test('index.json이 가리키는 수정본 파일이 없음', () async {
      await t.saveCustom(p, kang);
      final f = await tampered((a) => a.removeWhere((name, _) => name.endsWith('/1.hwo')));
      await expectRejected(f, BackupErrorCode.corrupt);
    });

    test('index.json에 없는 수정본 파일', () async {
      await t.saveCustom(p, kang);
      final f = await tampered((a) {
        final name = a.keys.firstWhere((n) => n.endsWith('/1.hws'));
        a[name.replaceFirst('/1.hws', '/2.hws')] = a[name]!;
      });
      await expectRejected(f, BackupErrorCode.corrupt);
    });

    test('잘못된 ASCII 폰트 이름', () async {
      final f = await tampered((a) {
        final m = manifestOf(a);
        ((m['project']! as Map)['font'] as Map)['asciiFamilyName'] = '한글';
        a['manifest.json'] = utf8.encode(jsonEncode(m));
      });
      await expectRejected(f, BackupErrorCode.corrupt);
    });
  });
}
