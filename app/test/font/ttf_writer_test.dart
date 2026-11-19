import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/font/glyph.dart';
import 'package:hwaeaek/font/ttf_writer.dart';

/// 저장소 루트의 검증 도구. 없으면 외부 검증 테스트는 건너뛴다.
final _python = File('../.venv-tools/bin/python');
const _validator = '../tools/validate_ttf.py';

GlyphOutline _box(int x0, int y0, int x1, int y1) => GlyphOutline([
  [
    GlyphPoint(x0, y0),
    GlyphPoint(x0, y1),
    GlyphPoint(x1, y1),
    GlyphPoint(x1, y0),
  ],
]);

Future<Map<String, dynamic>> _validate(File font, {int? expectCmap}) async {
  final result = await Process.run(_python.path, [
    _validator,
    font.path,
    if (expectCmap != null) ...['--expect-cmap', '$expectCmap'],
  ]);
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return jsonDecode(result.stdout as String) as Map<String, dynamic>;
}

void main() {
  test('작은 한글 폰트가 OTS와 fontTools 검증을 통과한다', () async {
    final bytes = buildTtf(
      FontSpec(
        familyName: '내손글씨',
        asciiFamilyName: 'Hwaeaek-1234abcd',
        versionMinor: 3,
        glyphs: {
          0x3131: FontGlyph(_box(100, 0, 900, 800), 1000), // ㄱ
          0xAC00: FontGlyph(_box(50, -50, 950, 850), 1000), // 가
          // 겹치는 두 획과 곡선 점
          0xAC01: FontGlyph(
            _box(0, 0, 600, 600).merged(
              GlyphOutline([
                [
                  const GlyphPoint(300, 300),
                  const GlyphPoint(300, 900, onCurve: false),
                  const GlyphPoint(900, 900),
                  const GlyphPoint(900, 300, onCurve: false),
                ],
              ]),
            ),
            1000,
          ),
        },
      ),
    );

    final dir = await Directory.systemTemp.createTemp('ttf_test');
    final font = File('${dir.path}/test.ttf')..writeAsBytesSync(bytes);
    if (!_python.existsSync()) {
      markTestSkipped('.venv-tools 없음: 외부 검증 생략');
      return;
    }
    // ㄱ, 가, 각 + 자동 추가된 공백
    final summary = await _validate(font, expectCmap: 4);
    expect(summary['numGlyphs'], 5);
    expect(summary['fontRevision'], 1.003);
    final names = summary['names'] as Map<String, dynamic>;
    expect(names['1/0x0409'], 'Hwaeaek-1234abcd');
    expect(names['1/0x0412'], '내손글씨');
    expect(names['6/0x0409'], 'Hwaeaek-1234abcd-Regular');
  });

  test('11,172자 전체 폰트도 검증을 통과하고 크기를 기록한다', () async {
    final glyphs = <int, FontGlyph>{
      for (var cp = 0xAC00; cp <= 0xD7A3; cp++)
        cp: FontGlyph(_box(cp % 97, 0, 900 + cp % 89, 800), 1000),
    };
    final sw = Stopwatch()..start();
    final bytes = buildTtf(
      FontSpec(familyName: 'Full', asciiFamilyName: 'Full', glyphs: glyphs),
    );
    sw.stop();
    // ignore: avoid_print
    print('11,172자 빌드 ${sw.elapsedMilliseconds}ms, ${bytes.length} bytes');

    final dir = await Directory.systemTemp.createTemp('ttf_test');
    final font = File('${dir.path}/full.ttf')..writeAsBytesSync(bytes);
    if (!_python.existsSync()) {
      markTestSkipped('.venv-tools 없음: 외부 검증 생략');
      return;
    }
    await _validate(font, expectCmap: 11173);
  });
}
