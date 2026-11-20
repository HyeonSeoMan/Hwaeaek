import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/domain/compose/composer.dart';
import 'package:hwaeaek/domain/glyph/glyph.dart';
import 'package:hwaeaek/domain/glyph/latin_set.dart';
import 'package:hwaeaek/domain/ink/ink.dart';

import '../../support/db.dart' show fixture;

GlyphOutline _box(int x0, int x1) => GlyphOutline([
  [GlyphPoint(x0, 0), GlyphPoint(x0, 600), GlyphPoint(x1, 600), GlyphPoint(x1, 0)],
]);

InkStroke _line(double x0, double y0, double x1, double y1) => InkStroke([
  for (var i = 0; i <= 20; i++)
    InkPoint(x0 + (x1 - x0) * i / 20, y0 + (y1 - y0) * i / 20),
]);

void main() {
  test('세트: 숫자 10, 영문 52, 문장부호, 한글과 겹치지 않음', () {
    expect(latinDigits, hasLength(10));
    expect(latinUpper.length + latinLower.length, 52);
    expect(isLatinGlyph('A'.runes.first), isTrue);
    expect(isLatinGlyph('…'.runes.first), isTrue);
    expect(isLatinGlyph('가'.runes.first), isFalse);
    expect(latinCodePoints, orderedEquals([...latinCodePoints]..sort()));
  });

  test('넓은 글자는 왼쪽 여백에 맞추고 폭 = 오른쪽 끝 + 여백', () {
    final a = alignLatin(_box(300, 700));
    expect(a.bounds!.xMin, LatinGuides.sideBearing);
    expect(latinAdvance(a), 400 + 2 * LatinGuides.sideBearing);
  });

  test('좁은 글자는 최소 폭 안에서 가운데', () {
    final a = alignLatin(_box(500, 540));
    expect(latinAdvance(a), LatinGuides.minAdvance);
    final b = a.bounds!;
    expect(b.xMin, (LatinGuides.minAdvance - 40) ~/ 2);
  });

  test('조합 엔진: 그린 영문은 그대로 쓰고, 그리지 않은 영문은 null', () {
    final withA = Map.of(fixture)..['A'] = [_line(200, 0, 400, 680), _line(400, 680, 600, 0)];
    final composer = HangulComposer(withA);
    final a = composer.compose('A'.runes.first)!;
    expect(a.bounds!.xMin, LatinGuides.sideBearing);
    expect(composer.compose('B'.runes.first), isNull);
    expect(HangulComposer.dependencies('A'.runes.first), {'A'});
  });
}
