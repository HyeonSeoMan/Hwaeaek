/// 조합 엔진 (PRD FR-04, Spec §6). 앱 안 표시와 TTF 빌드가 이 구현 하나를 공유한다.
///
/// 규칙 v1: 기본 글리프 **획의 점**을 모음 모양·받침 유무로 정한 자리(slot)에
/// 옮긴 뒤 펜을 다시 입힌다. 획 굵기가 자리 크기와 관계없이 고르다.
library;

import 'dart:math' as math;

import '../font/metrics.dart';
import '../glyph/glyph.dart';
import '../glyph/latin_set.dart';
import '../hangul/hangul.dart';
import '../ink/ink.dart';

/// 정규화 좌표(0~1, y 위 방향)의 자리.
class Slot {
  const Slot(this.x0, this.y0, this.x1, this.y1);

  final double x0, y0, x1, y1;
}

class _Layout {
  const _Layout(this.lead, this.vowel, [this.tail]);

  final Slot lead;
  final Slot vowel;
  final Slot? tail;
}

/// 규칙 v1의 모든 값 (Spec §6.2). 하나라도 바꾸면 [HangulComposer.ruleVersion]을 올린다.
class RuleV1Params {
  const RuleV1Params({
    this.slotPadding = 0.03,
    this.maxAspectDistortion = 1.6,
    this.pen = PenStyle.base,
    this.penScaleExponent = 0.35,
    this.minPenRatio = 0.5,
    this.compoundTailRaise = 0.06,
  });

  final double slotPadding;
  final double maxAspectDistortion;

  /// 조합 펜의 기준. 지름은 자모 축소율에 따라 줄어든다.
  final PenStyle pen;
  final double penScaleExponent;
  final double minPenRatio;
  final double compoundTailRaise;

  double penSizeFor(double scale) {
    final ratio = math.pow(scale.clamp(0.0, 1.0), penScaleExponent).toDouble();
    return (pen.size * ratio.clamp(minPenRatio, 1.0)).roundToDouble();
  }
}

const _layouts = {
  (VowelShape.vertical, false): _Layout(
    Slot(0.00, 0.08, 0.60, 0.92),
    Slot(0.55, 0.00, 1.00, 1.00),
  ),
  (VowelShape.horizontal, false): _Layout(
    Slot(0.12, 0.44, 0.88, 1.00),
    Slot(0.00, 0.02, 1.00, 0.50),
  ),
  (VowelShape.mixed, false): _Layout(
    Slot(0.02, 0.46, 0.62, 1.00),
    Slot(0.00, 0.02, 1.00, 1.00),
  ),
  (VowelShape.vertical, true): _Layout(
    Slot(0.00, 0.44, 0.60, 1.00),
    Slot(0.55, 0.36, 1.00, 1.00),
    Slot(0.12, 0.00, 0.88, 0.38),
  ),
  (VowelShape.horizontal, true): _Layout(
    Slot(0.15, 0.64, 0.85, 1.00),
    Slot(0.00, 0.36, 1.00, 0.66),
    Slot(0.12, 0.00, 0.88, 0.36),
  ),
  (VowelShape.mixed, true): _Layout(
    Slot(0.02, 0.62, 0.60, 1.00),
    Slot(0.00, 0.34, 1.00, 1.00),
    Slot(0.12, 0.00, 0.88, 0.34),
  ),
};

const _compoundLeft = Slot(0.0, 0.05, 0.52, 0.95);
const _compoundRight = Slot(0.48, 0.05, 1.0, 0.95);
const _fullSlot = Slot(0, 0, 1, 1);

/// 조합 펜 기준 반지름(Spec §6.2 6단계). 펜 지름이 줄어도 자리 계산은 이 값을 쓴다.
const _fitInset = 28.0;

/// 음절을 이루는 부품: 자리에 맞춰 놓은 자모 하나의 윤곽선. 같은 [key]는 항상 같은
/// 윤곽선이므로, TTF에서는 부품을 한 번만 넣고 음절이 참조한다(composite glyph).
class GlyphPart {
  const GlyphPart(this.key, this.outline);

  final String key;
  final GlyphOutline outline;
}

/// 자모 하나가 조합 오류임을 알리는 내부 신호.
class _ComposeError implements Exception {
  const _ComposeError();
}

class HangulComposer {
  HangulComposer(this.baseStrokes, {this.params = const RuleV1Params()});

  /// v1: 직선 다각형 윤곽. v2: 2차 곡선 맞춤(허용 오차 2).
  static const ruleVersion = 2;

  /// 역할 키(MVP: 호환 자모 1자) → 기본 글리프 획.
  final Map<String, List<InkStroke>> baseStrokes;
  final RuleV1Params params;

  /// 부품 키 → 윤곽선. 같은 자모·같은 자리는 여러 음절이 공유한다.
  final _parts = <String, GlyphOutline>{};

  /// 음절의 부품(초성 → 중성 → 종성, 겹자음은 왼쪽 → 오른쪽). 조합 오류면 null.
  /// 음절이 아니면 null.
  List<GlyphPart>? composeParts(int cp) {
    if (!Syllable.isSyllable(cp)) return null;
    try {
      final parts = _syllableParts(cp);
      if (parts == null) return null;
      var points = 0;
      for (final part in parts) {
        points += part.outline.pointCount;
      }
      return points > 0xFFFF ? null : parts;
    } on _ComposeError {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 음절 11,172자 + 호환 자모 51자의 윤곽선. 조합 오류면 null (Spec §6.2 오류 판정).
  /// 글자 하나를 계산하다 생긴 예외는 null로 바꾼다.
  GlyphOutline? compose(int cp) {
    try {
      final out = _compose(cp);
      if (out == null || out.isEmpty || out.pointCount > 0xFFFF) return null;
      for (final c in out.contours) {
        for (final p in c) {
          if (p.x < -32768 || p.x > 32767 || p.y < -32768 || p.y > 32767) {
            return null;
          }
        }
      }
      return out;
    } on _ComposeError {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 이 글자 조합에 영향을 주는 역할 키 (Spec §6.1). 겹자음 자리에는 겹자음 키와
  /// 구성 자음 키를 둘 다 넣는다.
  static Set<String> dependencies(int cp) {
    if (Syllable.isCompatJamo(cp)) return _jamoKeys(String.fromCharCode(cp));
    if (isLatinGlyph(cp)) return {String.fromCharCode(cp)};
    if (!Syllable.isSyllable(cp)) return const {};
    final s = Syllable.decompose(cp);
    return {
      ..._jamoKeys(s.lead),
      ..._jamoKeys(s.vowel),
      if (s.hasTail) ..._jamoKeys(s.tail),
    };
  }

  /// 기본 글리프 편집 가이드의 배치 영역 (Spec §5): 그 자모가 받침 없는 음절에서
  /// 놓이는 자리. 자음은 세로형 초성 자리, 모음은 모양별 중성 자리.
  static Slot guideSlotFor(String jamo) {
    if (jungseong.contains(jamo)) {
      return _layouts[(vowelShape(jamo), false)]!.vowel;
    }
    return _layouts[(VowelShape.vertical, false)]!.lead;
  }

  static Set<String> _jamoKeys(String j) {
    final pair = compoundConsonants[j];
    return pair == null ? {j} : {j, pair.$1, pair.$2};
  }

  GlyphOutline? _compose(int cp) {
    if (Syllable.isCompatJamo(cp)) {
      final j = String.fromCharCode(cp);
      final strokes = baseStrokes[j];
      // 단독 자모는 기본 글리프 획을 변환 없이 기본 펜으로 입힌다.
      if (strokes != null) return _ink(strokes, PenStyle.base);
      return _place(j, _fullSlot, padding: 0);
    }
    if (isLatinGlyph(cp)) {
      // 숫자·문장부호·영문은 조합하지 않고 그린 획을 그대로 쓴다(왼쪽 여백 정렬).
      final strokes = baseStrokes[String.fromCharCode(cp)];
      return strokes == null ? null : alignLatin(_ink(strokes, PenStyle.base));
    }
    final parts = _syllableParts(cp);
    return parts == null
        ? null
        : GlyphOutline([for (final p in parts) ...p.outline.contours]);
  }

  List<GlyphPart>? _syllableParts(int cp) {
    if (!Syllable.isSyllable(cp)) return null;

    final s = Syllable.decompose(cp);
    var layout = _layouts[(vowelShape(s.vowel), s.hasTail)]!;
    // 겹받침을 구성 자음으로 만들 때만 받침 자리를 높인다.
    if (s.hasTail &&
        !baseStrokes.containsKey(s.tail) &&
        compoundConsonants.containsKey(s.tail)) {
      layout = _raiseTail(layout, params.compoundTailRaise);
    }
    // 컨투어 순서: 초성 → 중성 → 종성 (Spec §6.2 7단계).
    final lead = _placeParts(s.lead, layout.lead);
    final vowel = _placeParts(s.vowel, layout.vowel);
    final tail = s.hasTail
        ? _placeParts(s.tail, layout.tail!)
        : const <GlyphPart>[];
    if (lead == null || vowel == null || tail == null) return null;
    return [...lead, ...vowel, ...tail];
  }

  /// 자모 [j]를 [slot]에 넣은 윤곽선(단독 겹자음용).
  GlyphOutline? _place(String j, Slot slot, {double? padding}) {
    final parts = _placeParts(j, slot, padding: padding);
    return parts == null
        ? null
        : GlyphOutline([for (final p in parts) ...p.outline.contours]);
  }

  /// 자모 [j]를 [slot]에 넣은 부품들. 기본 글리프가 없으면 겹자음은 구성 자음을
  /// 왼쪽 → 오른쪽으로 나란히 넣고, 그 외에는 null.
  List<GlyphPart>? _placeParts(String j, Slot slot, {double? padding}) {
    final p = padding ?? params.slotPadding;
    final inner = Slot(slot.x0 + p, slot.y0 + p, slot.x1 - p, slot.y1 - p);
    final strokes = baseStrokes[j];
    if (strokes != null) return [_part(j, strokes, inner)];
    final pair = compoundConsonants[j];
    if (pair == null) return null;
    final a = baseStrokes[pair.$1], b = baseStrokes[pair.$2];
    if (a == null || b == null) return null;
    return [
      _part(pair.$1, a, _sub(inner, _compoundLeft)),
      _part(pair.$2, b, _sub(inner, _compoundRight)),
    ];
  }

  /// 같은 자모·같은 자리의 부품은 한 번만 계산한다.
  GlyphPart _part(String jamo, List<InkStroke> strokes, Slot slot) {
    final key =
        '$jamo@${slot.x0.toStringAsFixed(5)},${slot.y0.toStringAsFixed(5)},'
        '${slot.x1.toStringAsFixed(5)},${slot.y1.toStringAsFixed(5)}';
    return GlyphPart(key, _parts[key] ??= _put(strokes, slot));
  }

  /// 획을 자리에 맞춰 옮기고 축소율에 맞는 펜으로 입힌다. 결과가 비면 조합 오류.
  GlyphOutline _put(List<InkStroke> strokes, Slot slot) {
    final b = _strokeBounds(strokes);
    if (b == null) throw const _ComposeError();
    final f = _fitTo(b, slot);
    final moved = [
      for (final s in strokes)
        InkStroke([
          for (final p in s.points)
            p.movedTo(p.x * f.scaleX + f.dx, p.y * f.scaleY + f.dy),
        ]),
    ];
    final pen = params.pen.withSize(
      params.penSizeFor(math.min(f.scaleX, f.scaleY)),
    );
    return _ink(moved, pen);
  }

  GlyphOutline _ink(List<InkStroke> strokes, PenStyle pen) {
    final out = strokesToOutline(strokes, pen: pen);
    if (out.isEmpty) throw const _ComposeError();
    return out;
  }

  /// 받침 자리 윗변을 [raise]만큼 올리고, 초성·중성 자리를 같은 만큼 위로 압축한다.
  static _Layout _raiseTail(_Layout l, double raise) {
    final tail = l.tail!;
    final base = math.min(l.lead.y0, l.vowel.y0);
    double remap(double y) => y <= base
        ? base + raise
        : base + raise + (y - base) * (1 - base - raise) / (1 - base);
    Slot squeeze(Slot s) => Slot(s.x0, remap(s.y0), s.x1, remap(s.y1));
    return _Layout(
      squeeze(l.lead),
      squeeze(l.vowel),
      Slot(tail.x0, tail.y0, tail.x1, tail.y1 + raise),
    );
  }

  /// [outer] 안의 상대 자리.
  static Slot _sub(Slot outer, Slot rel) {
    final w = outer.x1 - outer.x0, h = outer.y1 - outer.y0;
    return Slot(
      outer.x0 + rel.x0 * w,
      outer.y0 + rel.y0 * h,
      outer.x0 + rel.x1 * w,
      outer.y0 + rel.y1 * h,
    );
  }

  static (double, double, double, double)? _strokeBounds(
    List<InkStroke> strokes,
  ) {
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

  /// 범위 [b]를 자리에 맞춘다 (Spec §6.2 6단계).
  ({double scaleX, double scaleY, double dx, double dy}) _fitTo(
    (double, double, double, double) b,
    Slot slot,
  ) {
    const bw = CompositionArea.right - CompositionArea.left;
    const bh = CompositionArea.top - CompositionArea.bottom;
    var sx0 = CompositionArea.left + slot.x0 * bw;
    var sx1 = CompositionArea.left + slot.x1 * bw;
    var sy0 = CompositionArea.bottom + slot.y0 * bh;
    var sy1 = CompositionArea.bottom + slot.y1 * bh;
    final ix = math.min(_fitInset, (sx1 - sx0) / 4);
    final iy = math.min(_fitInset, (sy1 - sy0) / 4);
    sx0 += ix;
    sx1 -= ix;
    sy0 += iy;
    sy1 -= iy;

    final (gx0, gy0, gx1, gy1) = b;
    final gw = gx1 - gx0, gh = gy1 - gy0;
    // 점 하나처럼 두 방향 모두 퇴화하면 조합 오류.
    if (gw < 1 && gh < 1) throw const _ComposeError();
    var scaleX = gw < 1 ? double.infinity : (sx1 - sx0) / gw;
    var scaleY = gh < 1 ? double.infinity : (sy1 - sy0) / gh;
    if (scaleX.isInfinite) scaleX = scaleY;
    if (scaleY.isInfinite) scaleY = scaleX;
    final limit = params.maxAspectDistortion;
    if (scaleX / scaleY > limit) scaleX = scaleY * limit;
    if (scaleY / scaleX > limit) scaleY = scaleX * limit;

    final left = sx0 + ((sx1 - sx0) - gw * scaleX) / 2;
    final bottom = sy0 + ((sy1 - sy0) - gh * scaleY) / 2;
    return (
      scaleX: scaleX,
      scaleY: scaleY,
      dx: left - gx0 * scaleX,
      dy: bottom - gy0 * scaleY,
    );
  }
}
