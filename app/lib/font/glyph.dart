/// 폰트 단위(y 위 방향) 정수 좌표의 글리프 윤곽선 모델.
///
/// TrueType `glyf`와 같은 의미를 갖는다. 연속된 off-curve 점 사이에는
/// on-curve 중점이 암묵적으로 존재한다.
library;

class GlyphPoint {
  const GlyphPoint(this.x, this.y, {this.onCurve = true});

  final int x;
  final int y;
  final bool onCurve;

  @override
  bool operator ==(Object other) =>
      other is GlyphPoint &&
      other.x == x &&
      other.y == y &&
      other.onCurve == onCurve;

  @override
  int get hashCode => Object.hash(x, y, onCurve);

  @override
  String toString() => '($x,$y${onCurve ? '' : ' off'})';
}

typedef Contour = List<GlyphPoint>;

class GlyphOutline {
  const GlyphOutline(this.contours);

  static const empty = GlyphOutline([]);

  final List<Contour> contours;

  bool get isEmpty => contours.every((c) => c.isEmpty);

  int get pointCount => contours.fold(0, (sum, c) => sum + c.length);

  Bounds? get bounds {
    Bounds? b;
    for (final c in contours) {
      for (final p in c) {
        b = b == null ? Bounds(p.x, p.y, p.x, p.y) : b.including(p.x, p.y);
      }
    }
    return b;
  }

  /// 윤곽선을 [scaleX], [scaleY]로 확대한 뒤 [dx], [dy]만큼 옮긴다.
  /// 결정성을 위해 결과 좌표는 반올림한 정수다.
  GlyphOutline transformed({
    double scaleX = 1,
    double scaleY = 1,
    int dx = 0,
    int dy = 0,
  }) {
    return GlyphOutline([
      for (final c in contours)
        [
          for (final p in c)
            GlyphPoint(
              (p.x * scaleX).round() + dx,
              (p.y * scaleY).round() + dy,
              onCurve: p.onCurve,
            ),
        ],
    ]);
  }

  GlyphOutline merged(GlyphOutline other) =>
      GlyphOutline([...contours, ...other.contours]);
}

class Bounds {
  const Bounds(this.xMin, this.yMin, this.xMax, this.yMax);

  final int xMin;
  final int yMin;
  final int xMax;
  final int yMax;

  Bounds including(int x, int y) => Bounds(
    x < xMin ? x : xMin,
    y < yMin ? y : yMin,
    x > xMax ? x : xMax,
    y > yMax ? y : yMax,
  );

  Bounds union(Bounds o) => Bounds(
    o.xMin < xMin ? o.xMin : xMin,
    o.yMin < yMin ? o.yMin : yMin,
    o.xMax > xMax ? o.xMax : xMax,
    o.yMax > yMax ? o.yMax : yMax,
  );
}
