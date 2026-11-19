/// 개발 진입점: 획 픽스처로 기본 글리프를 채운 프로젝트를 하나 만들어 둔다.
/// `flutter run -t lib/main_dev.dart`
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'dev/stroke_fixture.dart';
import 'infra/db/glyph_dao.dart';
import 'infra/db/project_dao.dart';
import 'state/providers.dart';
import 'ui/app.dart';

const _devProjectName = '개발용 획 픽스처';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  final db = container.read(databaseProvider);
  final projects = ProjectDao(db);
  final existing = await (db.select(
    db.projects,
  )..where((p) => p.name.equals(_devProjectName))).get();
  if (existing.isEmpty) {
    final id = await projects.create(_devProjectName);
    final glyphs = GlyphDao(db);
    for (final MapEntry(:key, :value) in strokeFixture().entries) {
      await glyphs.saveBaseGlyph(id, key, value);
    }
  }
  runApp(
    UncontrolledProviderScope(container: container, child: const HwaeaekApp()),
  );
}
