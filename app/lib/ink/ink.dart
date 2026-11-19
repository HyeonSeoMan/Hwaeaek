/// 원본 획 데이터와 획 → 윤곽선 변환 (tech-stack.md ①~③).
library;

import 'package:perfect_freehand/perfect_freehand.dart';

import '../font/glyph.dart';

/// 폰트 단위(y 위 방향) 좌표의 획 점. [pressure]는 0~1, 없으면 시뮬레이션한다.
class InkPoint {
  const InkPoint(this.x, this.y, [this.pressure]);

  final double x;
  final double y;
  final double? pressure;
}

class InkStroke {
  const InkStroke(this.points);

  final List<InkPoint> points;
}

class PenStyle {
  const PenStyle({this.size = 64, this.thinning = 0.55, this.smoothing = 0.6});

  /// 폰트 단위 펜 지름.
  final double size;
  final double thinning;
  final double smoothing;
}

/// 획들을 하나의 글리프 윤곽선으로 만든다. 획마다 닫힌 윤곽 하나이며,
/// 겹친 획이 non-zero 규칙으로 합쳐지도록 모두 시계 방향(y 위 기준)으로 맞춘다.
GlyphOutline strokesToOutline(
  List<InkStroke> strokes, {
  PenStyle pen = const PenStyle(),
}) {
  final contours = <Contour>[];
  for (final stroke in strokes) {
    if (stroke.points.isEmpty) continue;
    final hasPressure = stroke.points.every((p) => p.pressure != null);
    final outline = getStroke(
      [for (final p in stroke.points) PointVector(p.x, p.y, p.pressure)],
      options: StrokeOptions(
        size: pen.size,
        thinning: pen.thinning,
        smoothing: pen.smoothing,
        simulatePressure: !hasPressure,
        isComplete: true,
      ),
    );
    final contour = <GlyphPoint>[];
    for (final o in outline) {
      final p = GlyphPoint(o.dx.round(), o.dy.round());
      if (contour.isEmpty || contour.last != p) contour.add(p);
    }
    if (contour.length > 1 && contour.first == contour.last) {
      contour.removeLast();
    }
    if (contour.length < 3) continue;
    contours.add(_signedArea(contour) > 0 ? contour.reversed.toList() : contour);
  }
  return GlyphOutline(contours);
}

/// y 위 좌표계에서 반시계 방향이면 양수.
double _signedArea(Contour c) {
  var a = 0.0;
  for (var i = 0; i < c.length; i++) {
    final p = c[i], q = c[(i + 1) % c.length];
    a += p.x * q.y - q.x * p.y;
  }
  return a / 2;
}
