/// 좌표계와 폰트 메트릭 상수 (Spec §2). 다른 코드는 숫자를 직접 쓰지 않는다.
library;

abstract final class FontMetrics {
  static const unitsPerEm = 1000;
  static const ascender = 800;
  static const descender = -200;
  static const lineGap = 0;

  /// 한글 음절·호환 자모 advance width (고정폭).
  static const hangulAdvance = 1000;
  static const spaceAdvance = 333;

  /// 메모 폰트 등 날짜가 의미 없는 폰트의 head.created/modified.
  static final fixedCreated = DateTime.utc(2026);
}

/// 조합 영역 (Spec §2): 조합 엔진이 자리를 계산하는 사각형.
abstract final class CompositionArea {
  static const left = 60;
  static const right = 940;
  static const bottom = -60;
  static const top = 800;
}
