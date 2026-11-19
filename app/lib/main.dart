import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app/font_session.dart';
import 'app/memo_screen.dart';
import 'dev/fixture_glyphs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // PoC: 사용자 손글씨 대신 개발용 픽스처(나눔손글씨 펜 자모)로 시작한다.
  final fixture = parseJamoFixture(
    await rootBundle.loadString('assets/dev/nanum_pen_jamo.json'),
  );
  runApp(HwaeaekApp(session: FontSession(fixture)));
}

class HwaeaekApp extends StatelessWidget {
  const HwaeaekApp({super.key, required this.session});

  final FontSession session;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '회애액',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF3B6E5A)),
      home: MemoScreen(session: session),
    );
  }
}
