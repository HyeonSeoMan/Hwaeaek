import 'package:material_ui/material_ui.dart';

import '../hangul/hangul.dart';
import 'font_session.dart';
import 'glyph_editor_screen.dart';
import 'glyph_painter.dart';

/// 기본 글리프 목록 (PRD FR-03). PoC: 호환 자모 51자를 모두 기본 글리프로 쓴다.
class BaseGlyphScreen extends StatelessWidget {
  const BaseGlyphScreen({super.key, required this.session});

  final FontSession session;

  static final _jamo = [
    for (var cp = compatJamoFirst; cp <= compatJamoLast; cp++)
      String.fromCharCode(cp),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('기본 글리프')),
        body: GridView.extent(
          maxCrossAxisExtent: 120,
          padding: const EdgeInsets.all(12),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final j in _jamo)
              InkWell(
                onTap: () async {
                  final strokes = await Navigator.push(
                    context,
                    MaterialPageRoute<List<dynamic>>(
                      builder: (_) => GlyphEditorScreen(
                        title: '기본 글리프 ‘$j’',
                        reference: session.baseGlyphs[j],
                      ),
                    ),
                  );
                  if (strokes != null) session.setBaseGlyph(j, strokes.cast());
                },
                child: Card.outlined(
                  child: Stack(
                    children: [
                      Positioned(left: 6, top: 4, child: Text(j)),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: GlyphPainter(session.baseGlyphs[j]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
