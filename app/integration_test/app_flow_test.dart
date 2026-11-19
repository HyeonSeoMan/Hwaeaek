/// 통합 테스트 (Spec §12): 작성 → 메모 → 다시 그리기 → 내보내기.
/// `flutter test integration_test -d macos` (iPad 시뮬레이터도 같음).
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/dev/stroke_fixture.dart';
import 'package:hwaeaek/domain/font/ttf_reader.dart';
import 'package:hwaeaek/infra/db/database.dart';
import 'package:hwaeaek/infra/db/glyph_dao.dart';
import 'package:hwaeaek/infra/db/project_dao.dart';
import 'package:hwaeaek/infra/platform/files.dart';
import 'package:hwaeaek/state/export_job.dart';
import 'package:hwaeaek/state/providers.dart';
import 'package:hwaeaek/ui/app.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

class _KeepDelivery implements FileDelivery {
  File? last;

  @override
  Future<bool> save(File file, {required String fileName}) async {
    last = file;
    return true;
  }

  @override
  Future<void> share(File file, {required String fileName, Rect? origin}) async => last = file;
}

/// 실제 앱에서는 커서 깜빡임 등으로 화면이 '안정'되지 않으므로 시간을 정해 기다린다.
Future<void> settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// [finder]가 나타날 때까지 최대 [seconds]초 기다린다.
Future<void> waitFor(WidgetTester tester, Finder finder, {int seconds = 30}) async {
  for (var i = 0; i < seconds * 10 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets, reason: '기다렸지만 나타나지 않음: $finder');
  // 페이지 전환 애니메이션이 끝날 때까지 기다린다(전환 중에는 탭 좌표가 어긋난다).
  await settle(tester, frames: 8);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('기본 글리프 → 메모 → 다시 그리기 → 내보내기', (tester) async {
    // 데스크톱 창 크기와 테스트 뷰 크기를 맞춘다(탭 좌표가 어긋나지 않게).
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    final projectId = await ProjectDao(db).create('통합 테스트');
    final glyphs = GlyphDao(db);
    for (final MapEntry(:key, :value) in strokeFixture().entries) {
      await glyphs.saveBaseGlyph(projectId, key, value);
    }
    final exports = await Directory.systemTemp.createTemp('hwaeaek_it');
    final delivery = _KeepDelivery();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          exportsRootProvider.overrideWith((ref) async => exports),
          fileDeliveryProvider.overrideWithValue(delivery),
        ],
        child: const HwaeaekApp(),
      ),
    );
    await settle(tester);

    // 프로젝트 → 새 메모 → 입력
    await waitFor(tester, find.text('통합 테스트'));
    await tester.tap(find.text('통합 테스트').first); // 제목과 폰트 이름이 같다
    await waitFor(tester, find.text('새 메모'));
    await tester.tap(find.text('새 메모'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('memo-field')), '강 나라');
    await settle(tester);

    // 강 다시 그리기
    final field = tester.widget<TextField>(find.byKey(const Key('memo-field')));
    field.controller!.selection = const TextSelection.collapsed(offset: 1);
    tester.state<EditableTextState>(find.byType(EditableText)).showToolbar();
    await settle(tester);
    await waitFor(tester, find.text('‘강’ 다시 그리기'));
    await tester.tap(find.text('‘강’ 다시 그리기'));
    await waitFor(tester, find.byKey(const Key('glyph-canvas')));
    final canvas = find.byKey(const Key('glyph-canvas'));
    await tester.dragFrom(tester.getCenter(canvas) - const Offset(80, 0), const Offset(160, 40));
    await settle(tester);
    await tester.tap(find.text('저장'));
    await settle(tester);
    expect(await glyphs.revisions(projectId, '강'.runes.first), hasLength(1));

    // 메모에서 나가 내보내기
    await tester.pageBack();
    await settle(tester);
    await tester.tap(find.byTooltip('TTF 내보내기'));
    await waitFor(tester, find.text('저장'));
    await tester.tap(find.text('저장'));
    await waitFor(tester, find.textContaining('폰트를 만들었습니다'));
    final info = readTtf(await delivery.last!.readAsBytes());
    expect(info.cmap.length, 1 + 11223);
    // 화면이 DB 구독을 놓은 뒤에 닫는다.
    await tester.pumpWidget(const SizedBox());
    await settle(tester, frames: 3);
    await db.close();
  });
}
