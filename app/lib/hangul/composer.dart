/// 조합 엔진 (PRD FR-04). 앱 안 표시와 TTF 빌드가 이 구현 하나를 공유한다.
///
/// 규칙 v0 (PoC): 자모마다 기본 글리프 하나를 두고, 모음 모양과 받침 유무로 정한
/// 자리(slot)에 맞춰 크기를 바꿔 넣는다. 위치별 자모 변형(보강 기본 글리프)은
/// OQ-01 실험 이후에 추가한다.
library;

import '../font/glyph.dart';
import 'hangul.dart';

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

class ComposerMetrics {
  const ComposerMetrics({
    this.advance = 1000,
    this.bodyLeft = 60,
    this.bodyRight = 940,
    this.bodyBottom = -60,
    this.bodyTop = 800,
    this.slotPadding = 0.03,
    this.maxAspectDistortion = 1.6,
  });

  final int advance;

  /// 글자 몸 상자 (폰트 단위).
  final int bodyLeft, bodyRight, bodyBottom, bodyTop;

  /// 자리 안쪽 여백 (정규화 비율).
  final double slotPadding;

  /// 가로·세로 배율 비가 이 값을 넘지 않게 한다(획 두께 왜곡 제한).
  final double maxAspectDistortion;
}

class HangulComposer {
  HangulComposer(this.baseGlyphs, {this.metrics = const ComposerMetrics()});

  static const ruleVersion = 0;

  /// 호환 자모 문자 → 기본 글리프 윤곽선 (폰트 단위).
  final Map<String, GlyphOutline> baseGlyphs;
  final ComposerMetrics metrics;

  /// 음절 또는 호환 자모의 윤곽선. 의존 기본 글리프가 없으면 null(조합 오류).
  GlyphOutline? compose(int cp) {
    if (Syllable.isCompatJamo(cp)) return _jamo(String.fromCharCode(cp));
    if (!Syllable.isSyllable(cp)) return null;

    final s = Syllable.decompose(cp);
    final layout = _layouts[(vowelShape(s.vowel), s.hasTail)]!;
    final lead = _jamo(s.lead);
    final vowel = _jamo(s.vowel);
    final tail = s.hasTail ? _jamo(s.tail) : GlyphOutline.empty;
    if (lead == null || vowel == null || tail == null) return null;

    var out = _place(lead, layout.lead).merged(_place(vowel, layout.vowel));
    if (s.hasTail) out = out.merged(_place(tail, layout.tail!));
    return out;
  }

  /// 단독 자모 글리프. 겹자음은 기본 글리프가 없으면 구성 자음으로 만든다.
  GlyphOutline? _jamo(String j) {
    final g = baseGlyphs[j];
    if (g != null) return g;
    final parts = compoundConsonants[j];
    if (parts == null) return null;
    final a = baseGlyphs[parts.$1];
    final b = baseGlyphs[parts.$2];
    if (a == null || b == null) return null;
    return _fit(a, const _Slot(0.0, 0.05, 0.52, 0.95)).merged(
      _fit(b, const _Slot(0.48, 0.05, 1.0, 0.95)),
    );
  }

  GlyphOutline _place(GlyphOutline jamo, _Slot slot) {
    final p = metrics.slotPadding;
    return _fit(
      jamo,
      _Slot(slot.x0 + p, slot.y0 + p, slot.x1 - p, slot.y1 - p),
    );
  }

  /// 윤곽선의 실제 범위를 자리에 맞춘다. 배율 비는 [maxAspectDistortion]으로 제한하고
  /// 남는 공간에서는 가운데 정렬한다.
  GlyphOutline _fit(GlyphOutline g, _Slot slot) {
    final b = g.bounds;
    if (b == null) return GlyphOutline.empty;
    final m = metrics;
    final bw = (m.bodyRight - m.bodyLeft).toDouble();
    final bh = (m.bodyTop - m.bodyBottom).toDouble();
    final sx0 = m.bodyLeft + slot.x0 * bw, sx1 = m.bodyLeft + slot.x1 * bw;
    final sy0 = m.bodyBottom + slot.y0 * bh, sy1 = m.bodyBottom + slot.y1 * bh;

    final gw = (b.xMax - b.xMin).clamp(1, 1 << 30).toDouble();
    final gh = (b.yMax - b.yMin).clamp(1, 1 << 30).toDouble();
    var scaleX = (sx1 - sx0) / gw;
    var scaleY = (sy1 - sy0) / gh;
    final limit = m.maxAspectDistortion;
    if (scaleX / scaleY > limit) scaleX = scaleY * limit;
    if (scaleY / scaleX > limit) scaleY = scaleX * limit;

    final w = gw * scaleX, h = gh * scaleY;
    final left = sx0 + ((sx1 - sx0) - w) / 2;
    final bottom = sy0 + ((sy1 - sy0) - h) / 2;
    return g.transformed(
      scaleX: scaleX,
      scaleY: scaleY,
      dx: (left - b.xMin * scaleX).round(),
      dy: (bottom - b.yMin * scaleY).round(),
    );
  }
}
