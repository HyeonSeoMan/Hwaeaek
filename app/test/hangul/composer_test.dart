import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/dev/fixture_glyphs.dart';
import 'package:hwaeaek/font/ttf_writer.dart';
import 'package:hwaeaek/hangul/composer.dart';
import 'package:hwaeaek/hangul/hangul.dart';

final _fixture = parseJamoFixture(
  File('assets/dev/nanum_pen_jamo.json').readAsStringSync(),
);

void main() {
  test('음절 분해', () {
    final s = Syllable.decompose('강'.runes.first);
    expect((s.lead, s.vowel, s.tail), ('ㄱ', 'ㅏ', 'ㅇ'));
    final t = Syllable.decompose('뷁'.runes.first);
    expect((t.lead, t.vowel, t.tail), ('ㅂ', 'ㅞ', 'ㄺ'));
  });

  test('픽스처로 11,172자와 호환 자모 51자가 모두 조합된다', () {
    final composer = HangulComposer(_fixture);
    for (var cp = syllableFirst; cp <= syllableLast; cp++) {
      expect(composer.compose(cp), isNotNull, reason: String.fromCharCode(cp));
    }
    for (var cp = compatJamoFirst; cp <= compatJamoLast; cp++) {
      expect(composer.compose(cp), isNotNull);
    }
  });

  test('조합은 결정적이다', () {
    final a = HangulComposer(_fixture).compose('뷁'.runes.first)!;
    final b = HangulComposer(_fixture).compose('뷁'.runes.first)!;
    expect(a.contours, b.contours);
  });

  test('의존 기본 글리프가 없으면 조합 오류(null), 겹자음은 구성 자음으로 만든다', () {
    final partial = Map.of(_fixture)
      ..remove('ㅎ')
      ..remove('ㄲ');
    final composer = HangulComposer(partial);
    expect(composer.compose('한'.runes.first), isNull);
    expect(composer.compose('깍'.runes.first), isNotNull);
  });

  test('픽스처 전체 폰트를 빌드해 검증하고 샘플 이미지를 만든다', () async {
    final composer = HangulComposer(_fixture);
    final sw = Stopwatch()..start();
    final glyphs = <int, FontGlyph>{
      for (var cp = compatJamoFirst; cp <= compatJamoLast; cp++)
        cp: FontGlyph(composer.compose(cp)!, 1000),
      for (var cp = syllableFirst; cp <= syllableLast; cp++)
        cp: FontGlyph(composer.compose(cp)!, 1000),
    };
    final composeMs = sw.elapsedMilliseconds;
    final bytes = buildTtf(
      FontSpec(
        familyName: '회애액 PoC',
        asciiFamilyName: 'HwaeaekPoC',
        ascender: 800,
        descender: -200,
        glyphs: glyphs,
      ),
    );
    // ignore: avoid_print
    print(
      '조합 ${composeMs}ms, 전체 ${sw.elapsedMilliseconds}ms, '
      '${(bytes.length / 1024 / 1024).toStringAsFixed(2)}MB',
    );

    final out = Directory('../build/poc')..createSync(recursive: true);
    final font = File('${out.path}/hwaeaek_poc.ttf')..writeAsBytesSync(bytes);
    final python = File('../.venv-tools/bin/python');
    if (!python.existsSync()) return;
    final v = await Process.run(python.path, [
      '-I',
      '../tools/validate_ttf.py',
      font.path,
      '--expect-cmap',
      '${11172 + 51 + 1}',
    ]);
    expect(v.exitCode, 0, reason: '${v.stderr}');
    await Process.run(python.path, [
      '-I',
      '../tools/render_sample.py',
      font.path,
      '${out.path}/sample.png',
      '다람쥐 헌 쳇바퀴에 타고파',
      '키스의 고유 조건은 입술끼리',
      '닭 볶음탕 뷁 왠지 꿇어앉아',
      'ㅋㅋㅋ ㅠㅠ 한글 손글씨',
    ]);
  });
}
