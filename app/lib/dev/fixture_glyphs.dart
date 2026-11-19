/// 개발용 기본 글리프 픽스처 로더 (tools/extract_jamo_fixture.py 출력 형식).
library;

import 'dart:convert';

import '../font/glyph.dart';

Map<String, GlyphOutline> parseJamoFixture(String json) {
  final data = jsonDecode(json) as Map<String, dynamic>;
  final glyphs = data['glyphs'] as Map<String, dynamic>;
  return {
    for (final MapEntry(:key, :value) in glyphs.entries)
      key: GlyphOutline([
        for (final c in (value as Map<String, dynamic>)['contours'] as List)
          [
            for (final p in c as List)
              GlyphPoint(p[0] as int, p[1] as int, onCurve: p[2] == 1),
          ],
      ]),
  };
}
