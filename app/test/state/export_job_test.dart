import 'dart:io';

import 'package:flutter/painting.dart' show Rect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/domain/font/ttf_reader.dart';
import 'package:hwaeaek/domain/ink/ink.dart';
import 'package:hwaeaek/infra/platform/files.dart';
import 'package:hwaeaek/state/export_job.dart';
import 'package:hwaeaek/state/providers.dart';

import '../support/db.dart';
import '../support/tools.dart';

class _FakeDelivery implements FileDelivery {
  final saved = <String>[];
  final shared = <String>[];

  @override
  Future<bool> save(File file, {required String fileName}) async {
    saved.add(fileName);
    return true;
  }

  @override
  Future<void> share(File file, {required String fileName, Rect? origin}) async {
    shared.add(fileName);
  }
}

void main() {
  late TestDb t;
  late String p;
  late Directory root;
  late _FakeDelivery delivery;
  late ProviderContainer c;

  setUp(() async {
    t = TestDb.memory();
    p = await t.projectWithBaseGlyphs();
    root = await Directory.systemTemp.createTemp('hwaeaek_exports');
    delivery = _FakeDelivery();
    c = ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(t.db),
        exportsRootProvider.overrideWith((ref) async => root),
        fileDeliveryProvider.overrideWithValue(delivery),
      ],
    );
  });
  tearDown(() => t.close());

  ExportJob job() => c.read(exportJobProvider(p).notifier);

  /// 결과 시트까지 진행한다. autoDispose provider라 구독을 유지한다.
  Future<ExportReady> buildToSheet() async {
    c.listen(exportJobProvider(p), (_, _) {});
    await job().start();
    final s = c.read(exportJobProvider(p));
    expect(s, isA<ExportReady>(), reason: s is ExportFailed ? s.message : '$s');
    return s as ExportReady;
  }

  Future<ExportDone> export(ExportTarget target) async {
    await buildToSheet();
    await job().deliver(target);
    final s = c.read(exportJobProvider(p));
    expect(s, isA<ExportDone>(), reason: s is ExportFailed ? s.message : '$s');
    return s as ExportDone;
  }

  test('TS-03 커스텀 강이 TTF에 그대로 들어가고, 폰트 버전 외 프로젝트 데이터는 변하지 않는다', () async {
    final custom = fixture['ㅇ']!;
    await t.saveCustom(p, kang);
    final before = await t.projects.get(p);
    final revisions = await t.count('custom_revisions');

    final done = await export(ExportTarget.save);
    final info = readTtf(await done.file.readAsBytes());
    expect(info.glyph(info.cmap[kang]!).contours, strokesToOutline(custom).contours);

    final after = await t.projects.get(p);
    expect(after.fontVersionMinor, before.fontVersionMinor + 1);
    expect(
      (after.glyphRevision, after.baseRevision, after.name, after.fontAsciiName),
      (before.glyphRevision, before.baseRevision, before.name, before.fontAsciiName),
    );
    expect(await t.count('custom_revisions'), revisions);
    expect(delivery.saved, [done.file.uri.pathSegments.last]);
  });

  test('TS-08 조합 오류 음절은 빠지고 목록이 결과 시트에 나오며 내보내기는 완료된다', () async {
    // 필수는 모두 있지만 ㅎ이 점 하나라 조합할 수 없다(UI 저장 방지를 우회한 데이터).
    await t.glyphs.saveBaseGlyph(p, 'ㅎ', [
      const InkStroke([InkPoint(500, 400), InkPoint(500.2, 400.3)]),
    ]);
    final ready = await buildToSheet();
    final excluded = ready.build.excluded.toSet();
    expect(excluded, containsAll(['한', '않', '흙'].map((s) => s.runes.first)));
    expect(excluded, isNot(contains(kang)));
    await job().deliver(ExportTarget.share);
    final done = c.read(exportJobProvider(p)) as ExportDone;
    final info = readTtf(await done.file.readAsBytes());
    expect(info.cmap.length, 1 + 11223 - excluded.length);
    expect(info.cmap.containsKey('한'.runes.first), isFalse);
  });

  test('TS-13 다시 내보내면 폰트 버전이 오른다', () async {
    final first = await export(ExportTarget.save);
    final second = await export(ExportTarget.save);
    expect(second.versionMinor, first.versionMinor + 1);
    final head = readTtf(await second.file.readAsBytes());
    expect(head.numGlyphs, greaterThan(0));
    expect(second.file.path, endsWith('-v${second.versionMinor}.ttf'));
  });

  test('TS-14 커밋 전에 실패하면 버전·사용자 데이터가 그대로이고 .part가 남지 않는다', () async {
    await buildToSheet();
    await exec(t.db, '''
      CREATE TEMP TRIGGER fail_commit BEFORE UPDATE OF font_version_minor ON projects
      BEGIN SELECT RAISE(ABORT, 'injected'); END''');
    await job().deliver(ExportTarget.save);
    expect(c.read(exportJobProvider(p)), isA<ExportFailed>());
    expect((await t.projects.get(p)).fontVersionMinor, 0);
    final files = Directory('${root.path}/$p').listSync();
    expect(files, isEmpty);
  });

  test('TS-14 이전 실행에서 남은 .part는 다음 내보내기 시작 때 지운다', () async {
    final dir = Directory('${root.path}/$p')..createSync(recursive: true);
    final stray = File('${dir.path}/old-v1.ttf.part')..writeAsStringSync('x');
    await buildToSheet();
    expect(stray.existsSync(), isFalse);
  });

  test('결과 시트에서 취소하면 아무것도 쓰지 않는다', () async {
    await buildToSheet();
    job().cancel();
    expect((await t.projects.get(p)).fontVersionMinor, 0);
    expect(Directory('${root.path}/$p').listSync(), isEmpty);
  });

  test('필수 기본 글리프가 없으면 내보낼 수 없다', () async {
    final fresh = await t.projects.create('빈');
    c.listen(exportJobProvider(fresh), (_, _) {});
    await c.read(exportJobProvider(fresh).notifier).start();
    expect(c.read(exportJobProvider(fresh)), isA<ExportFailed>());
  });

  test('파일은 최근 3개만 남긴다', () async {
    for (var i = 0; i < 4; i++) {
      await export(ExportTarget.save);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    final ttf = Directory('${root.path}/$p').listSync().where((f) => f.path.endsWith('.ttf'));
    expect(ttf, hasLength(3));
  });

  test('내보낸 TTF가 OTS·fontTools 검증을 통과한다', () async {
    await t.saveCustom(p, kang);
    final done = await export(ExportTarget.save);
    if (!toolsAvailable()) return;
    final summary = await validateTtf(done.file, expectCmap: 1 + 11223);
    expect(summary['fontRevision'], 1.001);
  });
}
