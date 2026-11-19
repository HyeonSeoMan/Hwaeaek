import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/infra/db/database.dart';
import 'package:hwaeaek/state/providers.dart';
import 'package:hwaeaek/ui/app.dart';
import 'package:hwaeaek/ui/frequency_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../support/db.dart';

void main() {
  testWidgets('FR-06 빈도순 목록: 가부터 보이고, 눌러서 다시 그리기로 간다', (tester) async {
    final t = TestDb(
      AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true)),
    );
    addTearDown(t.close);
    final p = await t.projectWithBaseGlyphs();
    await t.saveCustom(p, '각'.runes.first);
    final c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(t.db)]);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: HwaeaekApp(home: FrequencyScreen(projectId: p)),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();

    final first = find.byKey(Key('freq-${'가'.runes.first}'));
    expect(first, findsOneWidget);
    expect(find.text('내 글씨'), findsOneWidget); // 각(2번째)은 커스텀
    await tester.tap(first);
    await tester.pumpAndSettle();
    expect(find.text('‘가’ 다시 그리기'), findsOneWidget);
  });
}
