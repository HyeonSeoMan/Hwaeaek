import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/domain/decode_error.dart';
import 'package:hwaeaek/domain/glyph/glyph.dart';
import 'package:hwaeaek/domain/glyph/hwo1.dart';
import 'package:hwaeaek/domain/ink/hws1.dart';
import 'package:hwaeaek/domain/ink/ink.dart';
import 'package:hwaeaek/domain/ink/quantize.dart';

void main() {
  final strokes = [
    InkStroke([
      quantizedPoint(10.1, 20.2, pressure: 0.3, tilt: 0.4, orientation: 1.1, t: 0),
      quantizedPoint(30.3, 40.4, pressure: 0.6, t: 8),
    ]),
    InkStroke([quantizedPoint(-5.5, 700.7, t: 0)]),
  ];

  test('HWS1 왕복: 양자화된 점은 그대로 돌아온다', () {
    final back = decodeHws1(encodeHws1(strokes));
    expect(back.length, 2);
    expect(back[0].points, strokes[0].points);
    expect(back[1].points, strokes[1].points);
    expect(back[1].points.single.pressure, isNull);
    expect(encodeHws1(strokes).length, 4 + 2 + 2 * 4 + 3 * 24);
  });

  test('양자화: 같은 값을 두 번 양자화해도 같다', () {
    final p = quantizedPoint(0.1, 0.2, pressure: 0.7);
    expect(quantizedPoint(p.x, p.y, pressure: p.pressure), p);
  });

  test('HWS1 디코더가 잘못된 입력을 거부한다', () {
    final good = encodeHws1(strokes);
    Uint8List mutate(void Function(ByteData d) f) {
      final copy = Uint8List.fromList(good);
      f(ByteData.sublistView(copy));
      return copy;
    }

    final cases = {
      'magic': mutate((d) => d.setUint8(0, 0x58)),
      'strokeCount 0': mutate((d) => d.setUint16(4, 0, Endian.little)),
      'pressure > 1': mutate((d) => d.setFloat32(6 + 4 + 8, 1.5, Endian.little)),
      'NaN 좌표': mutate((d) => d.setFloat32(6 + 4, double.nan, Endian.little)),
      '시간 감소': mutate((d) {
        d.setUint32(6 + 4 + 20, 50, Endian.little);
        d.setUint32(6 + 4 + 24 + 20, 0, Endian.little);
      }),
      '남는 바이트': Uint8List.fromList([...good, 0]),
      '잘림': Uint8List.sublistView(good, 0, good.length - 1),
    };
    for (final MapEntry(:key, :value) in cases.entries) {
      expect(() => decodeHws1(value), throwsA(isA<DecodeError>()), reason: key);
    }
  });

  test('HWS1 인코더는 획 0개와 상한 초과를 받지 않는다', () {
    expect(() => encodeHws1(const []), throwsArgumentError);
    final tooMany = [
      for (var i = 0; i < InkLimits.maxStrokes + 1; i++)
        const InkStroke([InkPoint(0, 0)]),
    ];
    expect(() => encodeHws1(tooMany), throwsArgumentError);
  });

  test('HWO1 왕복과 거부', () {
    const outline = GlyphOutline([
      [GlyphPoint(0, 0), GlyphPoint(0, 100, onCurve: false), GlyphPoint(100, 100)],
      [GlyphPoint(-32768, 32767), GlyphPoint(1, 2), GlyphPoint(3, 4)],
    ]);
    final bytes = encodeHwo1(outline);
    expect(decodeHwo1(bytes).contours, outline.contours);
    expect(
      () => decodeHwo1(Uint8List.fromList([...bytes, 1])),
      throwsA(isA<DecodeError>()),
    );
    final badFlag = Uint8List.fromList(bytes)..[4 + 2 + 2 + 4] = 2;
    expect(() => decodeHwo1(badFlag), throwsA(isA<DecodeError>()));
  });
}
