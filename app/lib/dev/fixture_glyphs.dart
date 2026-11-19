/// 개발용 기본 글리프 픽스처 로더 (tools/extract_jamo_fixture.py 출력 형식).
library;

import 'dart:convert';

import '../font/glyph.dart';
import '../hangul/composer.dart';
import 'stroke_fixture.dart';

/// 나눔손글씨 펜 자모 윤곽선 (획 없음, 규칙 v0으로만 조합된다).
Map<String, BaseGlyph> parseJamoFixture(String json) {
  final data = jsonDecode(json) as Map<String, dynamic>;
  final glyphs = data['glyphs'] as Map<String, dynamic>;
  return {
    for (final MapEntry(:key, :value) in glyphs.entries)
      key: BaseGlyph.outline(GlyphOutline([
        for (final c in (value as Map<String, dynamic>)['contours'] as List)
          [
            for (final p in c as List)
              GlyphPoint(p[0] as int, p[1] as int, onCurve: p[2] == 1),
          ],
      ])),
  };
}

/// 기본 자모 35자 획 픽스처.
Map<String, BaseGlyph> strokeBaseGlyphs() => {
  for (final MapEntry(:key, :value) in strokeFixture().entries)
    key: BaseGlyph.strokes(value),
};
