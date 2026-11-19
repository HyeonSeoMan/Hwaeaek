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
  const PenStyle({
    this.size = 64,
    this.thinning = 0.55,
    this.smoothing = 0.6,
    this.tolerance = 2,
  });

  /// 폰트 단위 펜 지름.
  final double size;
  final double thinning;
  final double smoothing;

  /// 윤곽 단순화 허용 오차 (폰트 단위). 0이면 단순화하지 않는다.
  final double tolerance;
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
    final simplified = pen.tolerance > 0
        ? _simplifyClosed(outline.map((o) => (o.dx, o.dy)).toList(), pen.tolerance)
        : outline.map((o) => (o.dx, o.dy)).toList();
    final contour = <GlyphPoint>[];
    for (final (x, y) in simplified) {
      final p = GlyphPoint(x.round(), y.round());
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

typedef _Pt = (double, double);

/// 닫힌 다각형을 Douglas–Peucker로 단순화한다. 시작점과 가장 먼 점에서 둘로
/// 나눠 각각 열린 선으로 단순화한다.
List<_Pt> _simplifyClosed(List<_Pt> pts, double tolerance) {
  if (pts.length < 4) return pts;
  var far = 0;
  var best = -1.0;
  for (var i = 1; i < pts.length; i++) {
    final d = _dist2(pts[0], pts[i]);
    if (d > best) {
      best = d;
      far = i;
    }
  }
  final a = _simplifyOpen(pts.sublist(0, far + 1), tolerance);
  final b = _simplifyOpen([...pts.sublist(far), pts[0]], tolerance);
  return [...a, ...b.sublist(1, b.length - 1)];
}

List<_Pt> _simplifyOpen(List<_Pt> pts, double tolerance) {
  if (pts.length < 3) return pts;
  final keep = List.filled(pts.length, false)
    ..[0] = true
    ..[pts.length - 1] = true;
  final stack = [(0, pts.length - 1)];
  final tol2 = tolerance * tolerance;
  while (stack.isNotEmpty) {
    final (s, e) = stack.removeLast();
    var idx = -1;
    var max = tol2;
    for (var i = s + 1; i < e; i++) {
      final d = _segDist2(pts[i], pts[s], pts[e]);
      if (d > max) {
        max = d;
        idx = i;
      }
    }
    if (idx >= 0) {
      keep[idx] = true;
      stack
        ..add((s, idx))
        ..add((idx, e));
    }
  }
  return [
    for (var i = 0; i < pts.length; i++)
      if (keep[i]) pts[i],
  ];
}

double _dist2(_Pt a, _Pt b) =>
    (a.$1 - b.$1) * (a.$1 - b.$1) + (a.$2 - b.$2) * (a.$2 - b.$2);

double _segDist2(_Pt p, _Pt a, _Pt b) {
  final dx = b.$1 - a.$1, dy = b.$2 - a.$2;
  final len2 = dx * dx + dy * dy;
  if (len2 == 0) return _dist2(p, a);
  final t = (((p.$1 - a.$1) * dx + (p.$2 - a.$2) * dy) / len2).clamp(0.0, 1.0);
  return _dist2(p, (a.$1 + t * dx, a.$2 + t * dy));
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
