import 'package:flutter/rendering.dart';

import '../domain/font/metrics.dart';
import '../domain/glyph/glyph.dart';

/// 폰트 단위 윤곽선을 [side] 크기 정사각형 캔버스 좌표의 Path로 바꾼다.
/// 캔버스는 y = ascender(위)부터 descender(아래)까지 1000 단위를 담는다.
Path outlineToPath(GlyphOutline outline, double side) {
  final s = side / 1000;
  Offset map(GlyphPoint p) =>
      Offset(p.x * s, (FontMetrics.ascender - p.y) * s);
  Offset mid(GlyphPoint a, GlyphPoint b) => (map(a) + map(b)) / 2;

  final path = Path()..fillType = PathFillType.nonZero;
  for (final c in outline.contours) {
    if (c.length < 2) continue;
    // on-curve 점에서 시작한다. 모두 off-curve면 첫 두 점의 중점에서 시작한다.
    final start = c.indexWhere((p) => p.onCurve);
    final pts = start < 0 ? c : [...c.sublist(start), ...c.sublist(0, start)];
    final first = start < 0 ? mid(c[0], c[1]) : map(pts[0]);
    path.moveTo(first.dx, first.dy);
    GlyphPoint? control;
    // 시작점까지 다시 돌아와 윤곽을 닫는다.
    for (final p in [...pts.skip(start < 0 ? 0 : 1), pts[0]]) {
      if (!p.onCurve) {
        if (control != null) {
          final m = mid(control, p);
          final cp = map(control);
          path.quadraticBezierTo(cp.dx, cp.dy, m.dx, m.dy);
        }
        control = p;
      } else {
        final t = map(p);
        if (control != null) {
          final cp = map(control);
          path.quadraticBezierTo(cp.dx, cp.dy, t.dx, t.dy);
          control = null;
        } else {
          path.lineTo(t.dx, t.dy);
        }
      }
    }
    if (control != null) {
      final cp = map(control);
      path.quadraticBezierTo(cp.dx, cp.dy, first.dx, first.dy);
    }
    path.close();
  }
  return path;
}

class GlyphPainter extends CustomPainter {
  GlyphPainter(this.outline, {this.color = const Color(0xFF000000)});

  final GlyphOutline? outline;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final o = outline;
    if (o == null) return;
    canvas.drawPath(outlineToPath(o, size.shortestSide), Paint()..color = color);
  }

  @override
  bool shouldRepaint(GlyphPainter old) =>
      old.outline != outline || old.color != color;
}
