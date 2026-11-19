/// 조합 엔진 (PRD FR-04). 앱 안 표시와 TTF 빌드가 이 구현 하나를 공유한다.
///
/// 자모마다 기본 글리프 하나를 두고, 모음 모양과 받침 유무로 정한 자리(slot)에
/// 맞춰 넣는다. 위치별 자모 변형(보강 기본 글리프)은 OQ-01 실험 이후에 추가한다.
///
/// - 규칙 v0: 기본 글리프 **윤곽선**을 자리에 맞춰 축소한다. 획도 함께 가늘어진다.
/// - 규칙 v1: 기본 글리프 **획의 점**을 자리로 옮긴 뒤 같은 펜으로 다시 입힌다.
///   획 굵기가 자리 크기와 관계없이 일정하다. 획이 없는 기본 글리프는 v0으로 넣는다.
library;

import 'dart:math' as math;

import '../font/glyph.dart';
import '../ink/ink.dart';
import 'hangul.dart';

/// 기본 글리프: 원본 획(있으면)과 윤곽선.
class BaseGlyph {
  const BaseGlyph.outline(this.outline) : strokes = null;

  BaseGlyph.strokes(List<InkStroke> this.strokes, {PenStyle pen = const PenStyle()})
    : outline = strokesToOutline(strokes, pen: pen);

  final GlyphOutline outline;
  final List<InkStroke>? strokes;
}

enum CompositionRule {
  outlineScale(0),
  strokeScale(1);

  const CompositionRule(this.version);

  final int version;
}

/// 정규화 좌표(0~1, y 위 방향)의 자리.
class _Slot {
  const _Slot(this.x0, this.y0, this.x1, this.y1);

  final double x0, y0, x1, y1;
}

class _Layout {
  const _Layout(this.lead, this.vowel, [this.tail]);

  final _Slot lead;
  final _Slot vowel;
  final _Slot? tail;
}

const _layouts = {
  (VowelShape.vertical, false): _Layout(
    _Slot(0.00, 0.08, 0.60, 0.92),
    _Slot(0.55, 0.00, 1.00, 1.00),
  ),
  (VowelShape.horizontal, false): _Layout(
    _Slot(0.12, 0.44, 0.88, 1.00),
    _Slot(0.00, 0.02, 1.00, 0.50),
  ),
  (VowelShape.mixed, false): _Layout(
    _Slot(0.02, 0.46, 0.62, 1.00),
    _Slot(0.00, 0.02, 1.00, 1.00),
  ),
  (VowelShape.vertical, true): _Layout(
    _Slot(0.00, 0.44, 0.60, 1.00),
    _Slot(0.55, 0.36, 1.00, 1.00),
    _Slot(0.12, 0.00, 0.88, 0.38),
  ),
  (VowelShape.horizontal, true): _Layout(
    _Slot(0.15, 0.64, 0.85, 1.00),
    _Slot(0.00, 0.36, 1.00, 0.66),
    _Slot(0.12, 0.00, 0.88, 0.36),
  ),
  (VowelShape.mixed, true): _Layout(
    _Slot(0.02, 0.62, 0.60, 1.00),
    _Slot(0.00, 0.34, 1.00, 1.00),
    _Slot(0.12, 0.00, 0.88, 0.34),
  ),
};

const _compoundLeft = _Slot(0.0, 0.05, 0.52, 0.95);
const _compoundRight = _Slot(0.48, 0.05, 1.0, 0.95);
const _fullSlot = _Slot(0, 0, 1, 1);

class ComposerMetrics {
  const ComposerMetrics({
    this.advance = 1000,
    this.bodyLeft = 60,
    this.bodyRight = 940,
    this.bodyBottom = -60,
    this.bodyTop = 800,
    this.slotPadding = 0.03,
    this.maxAspectDistortion = 1.6,
    this.pen = const PenStyle(size: 56),
    this.penScaleExponent = 0.35,
    this.minPenRatio = 0.5,
    this.compoundTailRaise = 0.06,
  });

  /// 겹받침일 때 받침 자리를 높이는 양 (정규화 비율).
  final double compoundTailRaise;

  final int advance;

  /// 글자 몸 상자 (폰트 단위).
  final int bodyLeft, bodyRight, bodyBottom, bodyTop;

  /// 자리 안쪽 여백 (정규화 비율).
  final double slotPadding;

  /// 가로·세로 배율 비가 이 값을 넘지 않게 한다(획 두께 왜곡 제한).
  final double maxAspectDistortion;

  /// 규칙 v1에서 조합된 음절에 입히는 펜.
  final PenStyle pen;

  /// 규칙 v1에서 자모가 줄어든 비율 s에 대해 펜 지름을 `s^k`배로 한다.
  /// 0이면 펜 일정, 1이면 윤곽선 축소(v0)와 같다. 좁은 자리(겹받침 등)에서
  /// 획이 뭉치지 않게 한다.
  final double penScaleExponent;

  /// 펜 지름의 최소 배율.
  final double minPenRatio;

  double penSizeFor(double scale) {
    final ratio = math.pow(scale.clamp(0.0, 1.0), penScaleExponent).toDouble();
    return pen.size * ratio.clamp(minPenRatio, 1.0);
  }
}

/// 자리에 맞추는 변환: p' = (p * scale) + offset.
class _Fit {
  const _Fit(this.scaleX, this.scaleY, this.dx, this.dy);

  final double scaleX, scaleY, dx, dy;
}

/// 조합 중간 결과: 펜 지름별로 다시 입힐 획과 그대로 쓸 윤곽선.
class _Parts {
  final strokes = <double, List<InkStroke>>{};
  var outline = GlyphOutline.empty;
}

class HangulComposer {
  HangulComposer(
    this.baseGlyphs, {
    this.rule = CompositionRule.strokeScale,
    this.metrics = const ComposerMetrics(),
  });

  /// 호환 자모 문자 → 기본 글리프.
  final Map<String, BaseGlyph> baseGlyphs;
  final CompositionRule rule;
  final ComposerMetrics metrics;

  /// 음절 또는 호환 자모의 윤곽선. 의존 기본 글리프가 없으면 null(조합 오류).
  GlyphOutline? compose(int cp) {
    final parts = _Parts();
    if (Syllable.isCompatJamo(cp)) {
      final j = String.fromCharCode(cp);
      // 단독 자모는 기본 글리프를 그대로 쓴다(겹자음만 조합).
      final base = baseGlyphs[j];
      if (base != null) return base.outline;
      if (!_place(j, _fullSlot, parts, padding: 0)) return null;
      return _finish(parts);
    }
    if (!Syllable.isSyllable(cp)) return null;

    final s = Syllable.decompose(cp);
    var layout = _layouts[(vowelShape(s.vowel), s.hasTail)]!;
    // 겹받침은 자모 둘을 나란히 넣으므로 받침 자리를 높인다. 기본 글리프가
    // 있는 겹받침(사용자가 직접 그린 경우)은 한 자모로 보고 그대로 둔다.
    if (s.hasTail &&
        !baseGlyphs.containsKey(s.tail) &&
        compoundConsonants.containsKey(s.tail)) {
      layout = _raiseTail(layout, metrics.compoundTailRaise);
    }
    final ok =
        _place(s.lead, layout.lead, parts) &&
        _place(s.vowel, layout.vowel, parts) &&
        (!s.hasTail || _place(s.tail, layout.tail!, parts));
    return ok ? _finish(parts) : null;
  }

  GlyphOutline _finish(_Parts parts) {
    var out = parts.outline;
    final pen = metrics.pen;
    for (final MapEntry(key: size, value: strokes) in parts.strokes.entries) {
      out = strokesToOutline(
        strokes,
        pen: PenStyle(
          size: size,
          thinning: pen.thinning,
          smoothing: pen.smoothing,
          tolerance: pen.tolerance,
        ),
      ).merged(out);
    }
    return out;
  }

  /// 자모 [j]를 [slot]에 넣는다. 겹자음은 기본 글리프가 없으면 구성 자음을
  /// 자리 안에서 나란히 넣는다. 의존 기본 글리프가 없으면 false.
  bool _place(String j, _Slot slot, _Parts parts, {double? padding}) {
    final p = padding ?? metrics.slotPadding;
    final inner = _Slot(slot.x0 + p, slot.y0 + p, slot.x1 - p, slot.y1 - p);
    final base = baseGlyphs[j];
    if (base != null) {
      _put(base, inner, parts);
      return true;
    }
    final pair = compoundConsonants[j];
    if (pair == null) return false;
    final a = baseGlyphs[pair.$1], b = baseGlyphs[pair.$2];
    if (a == null || b == null) return false;
    _put(a, _sub(inner, _compoundLeft), parts);
    _put(b, _sub(inner, _compoundRight), parts);
    return true;
  }

  void _put(BaseGlyph g, _Slot slot, _Parts parts) {
    final strokes = g.strokes;
    if (rule == CompositionRule.strokeScale && strokes != null) {
      final b = _strokeBounds(strokes);
      if (b == null) return;
      // 다시 입힐 펜 반지름만큼 자리를 줄여 획이 자리를 넘지 않게 한다.
      final f = _fitTo(b, slot, inset: metrics.pen.size / 2);
      // 같은 펜 지름끼리 묶어 한 번에 입힌다. 반올림으로 묶음 수를 줄인다.
      final penSize = metrics
          .penSizeFor(math.min(f.scaleX, f.scaleY))
          .roundToDouble();
      final group = parts.strokes.putIfAbsent(penSize, () => []);
      for (final s in strokes) {
        group.add(
          InkStroke([
            for (final p in s.points)
              InkPoint(p.x * f.scaleX + f.dx, p.y * f.scaleY + f.dy, p.pressure),
          ]),
        );
      }
      return;
    }
    final b = g.outline.bounds;
    if (b == null) return;
    final f = _fitTo(
      (b.xMin.toDouble(), b.yMin.toDouble(), b.xMax.toDouble(), b.yMax.toDouble()),
      slot,
    );
    parts.outline = parts.outline.merged(
      g.outline.transformed(
        scaleX: f.scaleX,
        scaleY: f.scaleY,
        dx: f.dx.round(),
        dy: f.dy.round(),
      ),
    );
  }

  /// 받침 자리 윗변을 [raise]만큼 올리고, 초성·중성 자리의 아래쪽을 같은 만큼
  /// 위로 압축한다.
  static _Layout _raiseTail(_Layout l, double raise) {
    final tail = l.tail!;
    final oldBase = math.min(l.lead.y0, l.vowel.y0);
    final newBase = oldBase + raise;
    double remap(double y) =>
        y <= oldBase ? newBase : newBase + (y - oldBase) * (1 - newBase) / (1 - oldBase);
    _Slot squeeze(_Slot s) => _Slot(s.x0, remap(s.y0), s.x1, remap(s.y1));
    return _Layout(
      squeeze(l.lead),
      squeeze(l.vowel),
      _Slot(tail.x0, tail.y0, tail.x1, tail.y1 + raise),
    );
  }

  /// [outer] 안의 상대 자리.
  static _Slot _sub(_Slot outer, _Slot rel) {
    final w = outer.x1 - outer.x0, h = outer.y1 - outer.y0;
    return _Slot(
      outer.x0 + rel.x0 * w,
      outer.y0 + rel.y0 * h,
      outer.x0 + rel.x1 * w,
      outer.y0 + rel.y1 * h,
    );
  }

  static (double, double, double, double)? _strokeBounds(List<InkStroke> strokes) {
    double? x0, y0, x1, y1;
    for (final s in strokes) {
      for (final p in s.points) {
        x0 = x0 == null || p.x < x0 ? p.x : x0;
        y0 = y0 == null || p.y < y0 ? p.y : y0;
        x1 = x1 == null || p.x > x1 ? p.x : x1;
        y1 = y1 == null || p.y > y1 ? p.y : y1;
      }
    }
    return x0 == null ? null : (x0, y0!, x1!, y1!);
  }

  /// 범위 [b]를 자리에 맞춘다. 배율 비는 [ComposerMetrics.maxAspectDistortion]으로
  /// 제한하고 남는 공간에서는 가운데 정렬한다.
  _Fit _fitTo((double, double, double, double) b, _Slot slot, {double inset = 0}) {
    final m = metrics;
    final bw = (m.bodyRight - m.bodyLeft).toDouble();
    final bh = (m.bodyTop - m.bodyBottom).toDouble();
    var sx0 = m.bodyLeft + slot.x0 * bw, sx1 = m.bodyLeft + slot.x1 * bw;
    var sy0 = m.bodyBottom + slot.y0 * bh, sy1 = m.bodyBottom + slot.y1 * bh;
    // 자리가 펜보다 작아지지 않는 범위에서만 줄인다.
    final ix = inset.clamp(0, (sx1 - sx0) / 4), iy = inset.clamp(0, (sy1 - sy0) / 4);
    sx0 += ix;
    sx1 -= ix;
    sy0 += iy;
    sy1 -= iy;

    final (gx0, gy0, gx1, gy1) = b;
    // 가로나 세로로 얇은 자모(ㅡ, ㅣ)는 그 방향을 늘리지 않는다.
    final gw = gx1 - gx0, gh = gy1 - gy0;
    var scaleX = gw < 1 ? double.infinity : (sx1 - sx0) / gw;
    var scaleY = gh < 1 ? double.infinity : (sy1 - sy0) / gh;
    if (scaleX.isInfinite) scaleX = scaleY;
    if (scaleY.isInfinite) scaleY = scaleX;
    final limit = m.maxAspectDistortion;
    if (scaleX / scaleY > limit) scaleX = scaleY * limit;
    if (scaleY / scaleX > limit) scaleY = scaleX * limit;

    final left = sx0 + ((sx1 - sx0) - gw * scaleX) / 2;
    final bottom = sy0 + ((sy1 - sy0) - gh * scaleY) / 2;
    return _Fit(scaleX, scaleY, left - gx0 * scaleX, bottom - gy0 * scaleY);
  }
}
