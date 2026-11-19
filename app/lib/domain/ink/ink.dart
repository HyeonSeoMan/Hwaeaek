/// 원본 획 데이터와 획 → 윤곽선 변환 (Spec §3.1, §5.1).
library;

import 'package:perfect_freehand/perfect_freehand.dart';

import '../glyph/glyph.dart';

/// 폰트 단위(y 위 방향) 좌표의 획 점.
///
/// 포인터 입력과 HWS1 디코더는 [quantized]로 f32 값만 갖게 한다(Spec §5).
/// 조합 엔진이 배치하며 만드는 점은 double을 유지한다.
class InkPoint {
  const InkPoint(
    this.x,
    this.y, {
    this.pressure,
    this.tilt,
    this.orientation,
    this.t = 0,
  });

  final double x;
  final double y;

  /// 0~1. 없으면 `perfect_freehand`가 속도로 흉내 낸다.
  final double? pressure;

  /// 라디안, 0 = 수직. 저장만 하고 렌더링에 쓰지 않는다.
  final double? tilt;

  /// 라디안.
  final double? orientation;

  /// 획 시작부터 ms.
  final int t;

  InkPoint movedTo(double x, double y) => InkPoint(
    x,
    y,
    pressure: pressure,
    tilt: tilt,
    orientation: orientation,
    t: t,
  );

  @override
  bool operator ==(Object other) =>
      other is InkPoint &&
      other.x == x &&
      other.y == y &&
      other.pressure == pressure &&
      other.tilt == tilt &&
      other.orientation == orientation &&
      other.t == t;

  @override
  int get hashCode => Object.hash(x, y, pressure, tilt, orientation, t);
}

class InkStroke {
  const InkStroke(this.points);

  final List<InkPoint> points;
}

/// `perfect_freehand` easing. JSON에는 이름으로 저장한다.
enum PenEasing {
  identity(StrokeEasings.identity),
  easeInOut(StrokeEasings.easeInOut),
  easeOutCubic(StrokeEasings.easeOutCubic);

  const PenEasing(this.fn);

  final double Function(double) fn;
}

/// 펜 설정. 모든 값을 `StrokeOptions`에 명시적으로 넘겨 패키지의 변경 가능한
/// 정적 기본값에 기대지 않는다(Spec §5.1). 값은 규칙 버전의 일부다.
class PenStyle {
  const PenStyle({
    this.size = 56,
    this.thinning = 0.55,
    this.smoothing = 0.6,
    this.streamline = 0.5,
    this.easing = PenEasing.identity,
    this.startCap = true,
    this.startTaper = false,
    this.startEasing = PenEasing.easeInOut,
    this.endCap = true,
    this.endTaper = false,
    this.endEasing = PenEasing.easeOutCubic,
    this.tolerance = 2,
  });

  /// 기본 펜 (Spec §3.1): 편집 표시, 커스텀 저장, 단독 호환 자모.
  static const base = PenStyle();

  /// 폰트 단위 펜 지름.
  final double size;
  final double thinning;
  final double smoothing;
  final double streamline;
  final PenEasing easing;
  final bool startCap;
  final bool startTaper;
  final PenEasing startEasing;
  final bool endCap;
  final bool endTaper;
  final PenEasing endEasing;

  /// 윤곽 단순화 허용 오차 (폰트 단위). 0이면 단순화하지 않는다.
  final double tolerance;

  PenStyle withSize(double size) => PenStyle(
    size: size,
    thinning: thinning,
    smoothing: smoothing,
    streamline: streamline,
    easing: easing,
    startCap: startCap,
    startTaper: startTaper,
    startEasing: startEasing,
    endCap: endCap,
    endTaper: endTaper,
    endEasing: endEasing,
    tolerance: tolerance,
  );

  Map<String, Object> toJson() => {
    'size': size,
    'thinning': thinning,
    'smoothing': smoothing,
    'streamline': streamline,
    'easing': easing.name,
    'startCap': startCap,
    'startTaper': startTaper,
    'startEasing': startEasing.name,
    'endCap': endCap,
    'endTaper': endTaper,
    'endEasing': endEasing.name,
    'tolerance': tolerance,
  };

  StrokeOptions _options({required bool simulatePressure}) => StrokeOptions(
    size: size,
    thinning: thinning,
    smoothing: smoothing,
    streamline: streamline,
    easing: easing.fn,
    simulatePressure: simulatePressure,
    start: StrokeEndOptions.start(
      cap: startCap,
      taperEnabled: startTaper,
      easing: startEasing.fn,
    ),
    end: StrokeEndOptions.end(
      cap: endCap,
      taperEnabled: endTaper,
      easing: endEasing.fn,
    ),
    isComplete: true,
  );
}

/// 획 하나를 컨투어 하나로 만든다(Spec §5.1). 점 3개 미만이면 null.
Contour? strokeToContour(InkStroke stroke, PenStyle pen) {
  if (stroke.points.isEmpty) return null;
  final hasPressure = stroke.points.every((p) => p.pressure != null);
  final outline = getStroke(
    [for (final p in stroke.points) PointVector(p.x, p.y, p.pressure)],
    options: pen._options(simulatePressure: !hasPressure),
  );
  final raw = [for (final o in outline) (o.dx, o.dy)];
  final simplified = pen.tolerance > 0
      ? _simplifyClosed(raw, pen.tolerance)
      : raw;
  final contour = <GlyphPoint>[];
  for (final (x, y) in simplified) {
    final p = GlyphPoint(x.round(), y.round());
    if (contour.isEmpty || contour.last != p) contour.add(p);
  }
  if (contour.length > 1 && contour.first == contour.last) {
    contour.removeLast();
  }
  if (contour.length < 3) return null;
  return _signedArea(contour) > 0 ? contour.reversed.toList() : contour;
}

/// 획들을 하나의 글리프 윤곽선으로 만든다. 획마다 컨투어 하나이며, 겹친 획이
/// non-zero 규칙으로 합쳐지도록 모두 시계 방향(y 위 기준)으로 맞춘다.
GlyphOutline strokesToOutline(
  List<InkStroke> strokes, {
  PenStyle pen = PenStyle.base,
}) => GlyphOutline([
  for (final s in strokes) ?strokeToContour(s, pen),
]);

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
