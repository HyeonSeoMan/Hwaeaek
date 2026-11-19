import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../font/glyph.dart';
import '../ink/ink.dart';
import 'font_session.dart';
import 'glyph_painter.dart';

/// 글리프 편집 화면 (PRD FR-02, FR-05). 저장하면 획 목록을 돌려준다.
class GlyphEditorScreen extends StatefulWidget {
  const GlyphEditorScreen({super.key, required this.title, this.reference});

  final String title;

  /// 덧그리기용으로 흐리게 보여 줄 현재 글리프.
  final GlyphOutline? reference;

  @override
  State<GlyphEditorScreen> createState() => _GlyphEditorScreenState();
}

class _GlyphEditorScreenState extends State<GlyphEditorScreen> {
  final _strokes = <InkStroke>[];
  final _redo = <InkStroke>[];
  List<InkPoint>? _current;
  var _showReference = true;

  InkPoint _toFont(PointerEvent e, double side) {
    final pressure = e.kind == PointerDeviceKind.stylus && e.pressureMax > e.pressureMin
        ? ((e.pressure - e.pressureMin) / (e.pressureMax - e.pressureMin)).clamp(0.0, 1.0)
        : null;
    return InkPoint(
      e.localPosition.dx / side * 1000,
      FontSession.ascender - e.localPosition.dy / side * 1000,
      pressure,
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = [
      ..._strokes,
      if (_current != null) InkStroke(List.of(_current!)),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: '실행 취소',
            icon: const Icon(Icons.undo),
            onPressed: _strokes.isEmpty
                ? null
                : () => setState(() => _redo.add(_strokes.removeLast())),
          ),
          IconButton(
            tooltip: '다시 실행',
            icon: const Icon(Icons.redo),
            onPressed: _redo.isEmpty
                ? null
                : () => setState(() => _strokes.add(_redo.removeLast())),
          ),
          IconButton(
            tooltip: '모두 지우기',
            icon: const Icon(Icons.delete_outline),
            onPressed: _strokes.isEmpty
                ? null
                : () => setState(() {
                    _strokes.clear();
                    _redo.clear();
                  }),
          ),
          if (widget.reference != null)
            IconButton(
              tooltip: '기존 글리프 보기',
              icon: Icon(_showReference ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _showReference = !_showReference),
            ),
          FilledButton(
            onPressed: _strokes.isEmpty
                ? null
                : () => Navigator.pop(context, List.of(_strokes)),
            child: const Text('저장'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = (constraints.biggest.shortestSide - 32).clamp(200.0, 720.0);
            return SizedBox.square(
              dimension: side,
              child: Listener(
                onPointerDown: (e) => setState(() {
                  _current = [_toFont(e, side)];
                  _redo.clear();
                }),
                onPointerMove: (e) => setState(() => _current?.add(_toFont(e, side))),
                onPointerUp: (_) => setState(() {
                  final c = _current;
                  if (c != null && c.isNotEmpty) _strokes.add(InkStroke(c));
                  _current = null;
                }),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const CustomPaint(painter: _GuidePainter()),
                    if (_showReference && widget.reference != null)
                      CustomPaint(
                        painter: GlyphPainter(
                          widget.reference,
                          color: const Color(0x22000000),
                        ),
                      ),
                    CustomPaint(painter: GlyphPainter(strokesToOutline(live))),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 글자 몸 상자, 기준선 가이드.
class _GuidePainter extends CustomPainter {
  const _GuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 1000;
    double y(int fy) => (FontSession.ascender - fy) * s;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFAFAF7));
    final line = Paint()
      ..color = const Color(0xFFD0D0D0)
      ..strokeWidth = 1;
    // 조합 엔진의 글자 몸 상자 (ComposerMetrics 기본값)
    canvas.drawRect(
      Rect.fromLTRB(60 * s, y(800), 940 * s, y(-60)),
      line..style = PaintingStyle.stroke,
    );
    canvas.drawLine(Offset(0, y(0)), Offset(size.width, y(0)), line);
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      line..color = const Color(0xFFEAEAEA),
    );
  }

  @override
  bool shouldRepaint(_GuidePainter old) => false;
}
