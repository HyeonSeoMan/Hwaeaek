import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/infra/db/database.dart';
import 'package:hwaeaek/state/memo_font.dart';
import 'package:hwaeaek/state/providers.dart';
import 'package:hwaeaek/ui/app.dart';
import 'package:hwaeaek/ui/memo_screen.dart';
import 'package:hwaeaek/ui/memo_text.dart';
import 'package:hwaeaek/ui/project_screens.dart';
import 'package:material_ui/material_ui.dart';

import '../support/db.dart';

void main() {
  late TestDb t;
  late String projectId;
  late String memoId;
  var registered = 0;

  setUp(() async {
    t = TestDb(
      AppDatabase(
        DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
      ),
    );
    projectId = await t.projectWithBaseGlyphs();
    memoId = await t.memos.create(projectId);
    // 엔진 폰트 등록 대신 이름만 돌려준다.
    MemoFontNotifier.register = (_) async => 'hw_test_${++registered}';
  });
  tearDown(() => t.close());

  Future<ProviderContainer> pumpMemo(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(t.db)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: HwaeaekApp(home: MemoScreen(projectId: projectId, memoId: memoId)),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  MemoFontState fontOf(ProviderContainer c) =>
      c.read(memoFontProvider((projectId: projectId, memoId: memoId)));

  TextField field(WidgetTester tester) => tester.widget<TextField>(find.byKey(const Key('memo-field')));

  testWidgets('TS-09 필수 기본 글리프만 있는 프로젝트에서 한글 문장이 사용자 폰트로 표시된다', (tester) async {
    final c = await pumpMemo(tester);
    await tester.enterText(find.byKey(const Key('memo-field')), '다람쥐 헌 쳇바퀴에 타고파');
    await tester.pumpAndSettle();
    final font = fontOf(c);
    expect(font.family, isNotNull);
    expect(field(tester).style!.fontFamily, font.family);
    final syllables = '다람쥐헌쳇바퀴에타고파'.runes.toSet();
    expect(font.appliedCmap, containsAll(syllables));
    expect(font.knownErrors, isEmpty);
  });

  testWidgets('TS-11 조합 중 호환 자모와 음절도 사용자 폰트에 들어간다', (tester) async {
    final c = await pumpMemo(tester);
    final memo = find.byKey(const Key('memo-field'));
    for (final step in ['ㄱ', '가', '강']) {
      // 한글 입력기가 조합 중인 상태를 흉내 낸다.
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: step,
          selection: TextSelection.collapsed(offset: step.length),
          composing: TextRange(start: 0, end: step.length),
        ),
      );
      await tester.pumpAndSettle();
      expect(fontOf(c).appliedCmap, contains(step.runes.first), reason: step);
    }
    expect(tester.widget<TextField>(memo).controller!.text, '강');
  });

  testWidgets('TS-19 폰트에 없는 문자는 회색 점선 밑줄로 구분한다', (tester) async {
    await pumpMemo(tester);
    await tester.enterText(find.byKey(const Key('memo-field')), 'ab 강');
    await tester.pumpAndSettle();
    final controller = field(tester).controller! as MemoTextController;
    final span = controller.buildTextSpan(
      context: tester.element(find.byKey(const Key('memo-field'))),
      withComposing: false,
    );
    final styled = <String, TextStyle?>{};
    span.visitChildren((s) {
      if (s is TextSpan && s.text != null) styled[s.text!] = s.style;
      return true;
    });
    expect(styled['ab']?.decorationStyle, TextDecorationStyle.dotted);
    expect(styled.entries.where((e) => e.key.contains('강')).single.value, isNull);
  });

  testWidgets('조합 오류 음절(의존 기본 글리프 없음)은 knownErrors로 대체 표시된다', (tester) async {
    await exec(t.db, "DELETE FROM base_glyphs WHERE role_key = 'ㅎ'");
    final c = await pumpMemo(tester);
    await tester.enterText(find.byKey(const Key('memo-field')), '한강');
    await tester.pumpAndSettle();
    expect(fontOf(c).knownErrors, {'한'.runes.first});
    expect(fontOf(c).appliedCmap, contains('강'.runes.first));
  });

  testWidgets('붙여넣은 첫가끝 한글은 정규화되고, 메모 저장도 정규화된 값이다', (tester) async {
    await pumpMemo(tester);
    await tester.enterText(
      find.byKey(const Key('memo-field')),
      String.fromCharCodes([0x1100, 0x1161, 0x11BC]),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(field(tester).controller!.text, '강');
    expect((await t.memos.get(memoId)).text$, '강');
  });

  testWidgets('TS-10 메모에서 강을 골라 다시 그리고 저장하면 같은 위치로 돌아오고 새 강이 쓰인다', (tester) async {
    await t.memos.updateText(memoId, '강 나라');
    final c = await pumpMemo(tester);
    final memo = find.byKey(const Key('memo-field'));
    final controller = field(tester).controller!;
    controller.selection = const TextSelection.collapsed(offset: 1); // '강' 뒤
    await tester.pumpAndSettle();
    final before = fontOf(c).builtFromRevision;

    // 문맥 메뉴를 띄운다(롱프레스는 단어를 선택하므로 선택을 다시 커서로 둔다).
    final state = tester.state<EditableTextState>(find.byType(EditableText));
    state.showToolbar();
    controller.selection = const TextSelection.collapsed(offset: 1);
    await tester.pumpAndSettle();
    await tester.tap(find.text('‘강’ 다시 그리기'));
    await tester.pumpAndSettle();

    final canvas = find.byKey(const Key('glyph-canvas'));
    expect(canvas, findsOneWidget);
    await tester.dragFrom(tester.getCenter(canvas) - const Offset(80, 0), const Offset(160, 40));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('glyph-canvas')), findsNothing);
    expect(memo, findsOneWidget);
    expect(controller.selection, const TextSelection.collapsed(offset: 1));
    expect(await t.glyphs.revisions(projectId, '강'.runes.first), hasLength(1));
    expect(fontOf(c).builtFromRevision, greaterThan(before));
    expect(find.text('실행 취소'), findsOneWidget);
  });

  testWidgets('메모 화면을 바로 나가도 마지막 입력이 저장된다', (tester) async {
    await pumpMemo(tester);
    await tester.enterText(find.byKey(const Key('memo-field')), '마지막 글');
    await tester.pump(const Duration(milliseconds: 100)); // 1초 디바운스 전
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect((await t.memos.get(memoId)).text$, '마지막 글');
  });

  testWidgets('필수 기본 글리프가 없으면 새 메모를 만들 수 없고, 다 쓰면 만들 수 있다', (tester) async {
    final fresh = await t.projects.create('새 프로젝트');
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(t.db)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: HwaeaekApp(home: ProjectHomeScreen(projectId: fresh)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('새 메모'), findsNothing);
    expect(find.textContaining('기본 글리프 0 / 35'), findsOneWidget);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: HwaeaekApp(home: ProjectHomeScreen(projectId: projectId)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('새 메모'), findsOneWidget);
    await tester.tap(find.text('새 메모'));
    await tester.pumpAndSettle();
    expect(find.byType(MemoScreen), findsOneWidget);
  });
}
