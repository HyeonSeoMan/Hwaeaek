import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/domain/font/metrics.dart';
import 'package:hwaeaek/domain/font/ttf_reader.dart';
import 'package:hwaeaek/domain/font/ttf_writer.dart';
import 'package:hwaeaek/domain/glyph/glyph.dart';

import '../../support/tools.dart';

GlyphOutline _box(int x0, int y0, int x1, int y1) => GlyphOutline([
  [
    GlyphPoint(x0, y0),
    GlyphPoint(x0, y1),
    GlyphPoint(x1, y1),
    GlyphPoint(x1, y0),
  ],
]);

final _created = DateTime.utc(2026, 11, 19, 12);

void main() {
  final small = FontSpec(
    familyName: '내손글씨',
    asciiFamilyName: 'Hwaeaek-1234abcd',
    versionMinor: 3,
    created: _created,
    glyphs: {
      0x3131: FontGlyph(_box(100, 0, 900, 700), 1000), // ㄱ
      0xAC00: FontGlyph(_box(50, -50, 950, 750), 1000), // 가
      // 겹치는 두 컨투어와 off-curve 점
      0xAC01: FontGlyph(
        _box(0, 0, 600, 600).merged(
          const GlyphOutline([
            [
              GlyphPoint(300, 300),
              GlyphPoint(300, 780, onCurve: false),
              GlyphPoint(900, 780),
              GlyphPoint(900, 300, onCurve: false),
            ],
          ]),
        ),
        1000,
      ),
    },
  );

  test('기기 안 리더: cmap = 1(공백) + 유효 글리프, numGlyphs = cmap + 1 (Spec §7.2)', () {
    final info = readTtf(buildTtf(small));
    expect(info.cmap.length, 1 + 3);
    expect(info.numGlyphs, info.cmap.length + 1);
    expect(info.cmap.keys, containsAll([0x20, 0x3131, 0xAC00, 0xAC01]));
  });

  test('리더로 읽은 글리프가 입력 윤곽선과 같다', () {
    final info = readTtf(buildTtf(small));
    for (final cp in [0x3131, 0xAC00, 0xAC01]) {
      expect(info.glyph(info.cmap[cp]!).contours, small.glyphs[cp]!.outline.contours);
    }
    expect(info.glyph(info.cmap[0x20]!).isEmpty, isTrue);
  });

  test('리더가 손상된 바이트를 거부한다', () {
    final bytes = buildTtf(small);
    bytes[bytes.length - 3] ^= 0xFF;
    expect(() => readTtf(bytes), throwsA(anything));
  });

  test('u16 범위를 넘는 점 수는 잘라 쓰지 않고 예외를 던진다', () {
    final huge = GlyphOutline([
      [for (var i = 0; i < 70000; i++) GlyphPoint(i % 1000, i % 700)],
    ]);
    expect(
      () => buildTtf(
        FontSpec(
          familyName: 'x',
          asciiFamilyName: 'x',
          created: _created,
          glyphs: {0xAC00: FontGlyph(huge, 1000)},
        ),
      ),
      throwsRangeError,
    );
  });

  test('작은 한글 폰트가 OTS와 fontTools 검증을 통과한다', () async {
    final dir = await Directory.systemTemp.createTemp('ttf_test');
    final font = File('${dir.path}/test.ttf')..writeAsBytesSync(buildTtf(small));
    if (!toolsAvailable()) return;
    final summary = await validateTtf(font, expectCmap: 4);
    expect(summary['numGlyphs'], 5);
    expect(summary['fontRevision'], 1.003);
    final names = summary['names'] as Map<String, dynamic>;
    expect(names['1/0x0409'], 'Hwaeaek-1234abcd');
    expect(names['1/0x0412'], '내손글씨');
    expect(names['6/0x0409'], 'Hwaeaek-1234abcd-Regular');
  });

  test('11,172자 전체 폰트도 검증을 통과한다', () async {
    final bytes = buildTtf(
      FontSpec(
        familyName: 'Full',
        asciiFamilyName: 'Full',
        created: FontMetrics.fixedCreated,
        glyphs: {
          for (var cp = 0xAC00; cp <= 0xD7A3; cp++)
            cp: FontGlyph(_box(cp % 97, 0, 900 + cp % 89, 700), 1000),
        },
      ),
    );
    expect(readTtf(bytes).cmap.length, 11173);
    final dir = await Directory.systemTemp.createTemp('ttf_test');
    final font = File('${dir.path}/full.ttf')..writeAsBytesSync(bytes);
    if (!toolsAvailable()) return;
    await validateTtf(font, expectCmap: 11173);
  });
}
