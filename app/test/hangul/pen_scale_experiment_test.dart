import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/dev/fixture_glyphs.dart';
import 'package:hwaeaek/font/ttf_writer.dart';
import 'package:hwaeaek/hangul/composer.dart';

/// 겹받침 뭉침 실험 (G0 3회차): 펜 조절 지수 k와 겹받침 자리 높이기 비교 이미지.
void main() {
  const lines = [
    '닭 꿇 뷁 읽 밟 앉 핥',
    '없 삶 넓 쀍 휂 똠 쌂',
    '한글 손글씨 다람쥐',
  ];
  // (펜 조절 지수 k, 겹받침 자리 높이기)
  const configs = [(0.0, 0.0), (0.35, 0.0), (0.35, 0.06), (0.35, 0.1)];

  test('펜 조절 지수·겹받침 자리 비교 이미지', () async {
    final base = strokeBaseGlyphs();
    final cps = {for (final l in lines) ...l.runes.where((r) => r > 0x20)};
    final out = Directory('../build/poc')..createSync(recursive: true);
    final files = <String>[];
    for (final (k, raise) in configs) {
      final name = 'k${(k * 100).round()}_r${(raise * 100).round()}';
      final composer = HangulComposer(
        base,
        metrics: ComposerMetrics(penScaleExponent: k, compoundTailRaise: raise),
      );
      final bytes = buildTtf(
        FontSpec(
          familyName: name,
          asciiFamilyName: name,
          ascender: 800,
          descender: -200,
          glyphs: {for (final cp in cps) cp: FontGlyph(composer.compose(cp)!, 1000)},
        ),
      );
      final f = File('${out.path}/pen_$name.ttf')
        ..writeAsBytesSync(bytes);
      files.add(f.path);
    }
    final python = File('../.venv-tools/bin/python');
    if (!python.existsSync()) return;
    final r = await Process.run(python.path, [
      '-I',
      '../tools/render_sample.py',
      files.first,
      '${out.path}/pen_scale_compare.png',
      ...lines,
      for (final f in files.skip(1)) ...['--compare', f],
    ]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  });
}
