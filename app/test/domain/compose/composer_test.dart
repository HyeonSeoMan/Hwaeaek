import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/dev/stroke_fixture.dart';
import 'package:hwaeaek/domain/compose/composer.dart';
import 'package:hwaeaek/domain/font/metrics.dart';
import 'package:hwaeaek/domain/font/ttf_reader.dart';
import 'package:hwaeaek/domain/font/ttf_writer.dart';
import 'package:hwaeaek/domain/glyph/glyph.dart';
import 'package:hwaeaek/domain/glyph/hwo1.dart';
import 'package:hwaeaek/domain/hangul/hangul.dart';
import 'package:hwaeaek/domain/ink/hws1.dart';
import 'package:hwaeaek/domain/ink/ink.dart';

import '../../support/tools.dart';

final _fixture = strokeFixture();

int _cp(String s) => s.runes.first;

/// 호환 자모 51 + 음절 11,172 (Spec §6.3 골든 범위).
Iterable<int> get _allCodePoints sync* {
  for (var cp = compatJamoFirst; cp <= compatJamoLast; cp++) {
    yield cp;
  }
  for (var cp = syllableFirst; cp <= syllableLast; cp++) {
    yield cp;
  }
}

void main() {
  test('음절 분해', () {
    final s = Syllable.decompose(_cp('강'));
    expect((s.lead, s.vowel, s.tail), ('ㄱ', 'ㅏ', 'ㅇ'));
    final t = Syllable.decompose(_cp('뷁'));
    expect((t.lead, t.vowel, t.tail), ('ㅂ', 'ㅞ', 'ㄺ'));
  });

  test('필수 35자 픽스처로 음절 11,172자와 호환 자모 51자가 모두 조합된다', () {
    final composer = HangulComposer(_fixture);
    for (final cp in _allCodePoints) {
      expect(composer.compose(cp), isNotNull, reason: String.fromCharCode(cp));
    }
  });

  test('dependencies: 겹자음 자리에는 겹자음 키와 구성 자음 키를 둘 다 넣는다', () {
    expect(HangulComposer.dependencies(_cp('강')), {'ㄱ', 'ㅏ', 'ㅇ'});
    expect(HangulComposer.dependencies(_cp('닭')), {'ㄷ', 'ㅏ', 'ㄺ', 'ㄹ', 'ㄱ'});
    expect(HangulComposer.dependencies(_cp('ㄲ')), {'ㄲ', 'ㄱ'});
  });

  test('TS-01 기대 집합: 기본 글리프 ㄱ을 바꾸면 dependencies에 ㄱ이 있는 글자만 바뀐다', () {
    final before = HangulComposer(_fixture);
    // 평행 이동·확대는 자리 맞추기로 사라지므로 모양을 바꾼다: 마지막 점만 옮긴다.
    final g = _fixture['ㄱ']!.first.points;
    final changed = Map.of(_fixture)
      ..['ㄱ'] = [
        InkStroke([...g.take(g.length - 1), g.last.movedTo(g.last.x - 150, g.last.y + 200)]),
      ];
    final after = HangulComposer(changed);
    for (final cp in ['가', '각', '닭', '꿇', '나', '한', 'ㄱ', 'ㄲ'].map(_cp)) {
      final depends = HangulComposer.dependencies(cp).contains('ㄱ');
      final same = before.compose(cp)!.contours.toString() ==
          after.compose(cp)!.contours.toString();
      expect(same, !depends, reason: String.fromCharCode(cp));
    }
  });

  test('의존 기본 글리프가 없으면 조합 오류, 겹자음은 구성 자음으로 만든다', () {
    final partial = Map.of(_fixture)..remove('ㅎ');
    final composer = HangulComposer(partial);
    expect(composer.compose(_cp('한')), isNull);
    expect(composer.compose(_cp('깍')), isNotNull); // ㄲ 없음 → ㄱ ㄱ
    expect(composer.compose(_cp('않')), isNull); // ㄶ = ㄴ + ㅎ
  });

  test('점 하나짜리 기본 글리프는 NaN 없이 조합 오류가 된다', () {
    final dot = Map.of(_fixture)
      ..['ㅇ'] = [
        const InkStroke([InkPoint(500, 400), InkPoint(500.2, 400.3)]),
      ];
    final composer = HangulComposer(dot);
    expect(composer.compose(_cp('아')), isNull);
    expect(composer.compose(_cp('가')), isNotNull);
  });

  test('컨투어 순서: 초성 → 중성 → 종성', () {
    final composer = HangulComposer(_fixture);
    final full = composer.compose(_cp('강'))!;
    final lead = composer.compose(_cp('가'))!; // 다른 레이아웃이라 비교용이 아님
    expect(full.contours.length, greaterThan(lead.contours.length));
    // 초성 ㄱ(1획)이 먼저, 종성 ㅇ(1획)이 마지막: 첫 컨투어는 위쪽, 마지막은 아래쪽.
    int top(Contour c) => c.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    expect(top(full.contours.first), greaterThan(top(full.contours.last)));
  });

  test('HWS1 왕복 후 조합 결과가 같다 (f32 양자화, Spec §5)', () {
    final roundTrip = {
      for (final MapEntry(:key, :value) in _fixture.entries)
        key: decodeHws1(encodeHws1(value)),
    };
    final a = HangulComposer(_fixture);
    final b = HangulComposer(roundTrip);
    for (final cp in ['강', '뷁', '닭', 'ㅋ', '읽'].map(_cp)) {
      expect(b.compose(cp)!.contours, a.compose(cp)!.contours);
    }
  });

  test('TS-12 규칙 v1 골든 해시 (Spec §6.3)', () {
    final composer = HangulComposer(_fixture);
    final bytes = BytesBuilder(copy: false);
    for (final cp in _allCodePoints) {
      bytes.add(encodeHwo1(composer.compose(cp)!));
    }
    final hash = sha256.convert(bytes.toBytes()).toString();
    final golden = File(
      'test/golden/compose_v${HangulComposer.ruleVersion}.sha256',
    );
    if (autoUpdateGoldenFiles || !golden.existsSync()) {
      golden.writeAsStringSync('$hash\n');
    }
    expect(hash, golden.readAsStringSync().trim());
  });

  test('TS-12 앱 표시용 윤곽선과 TTF 안의 윤곽선이 같다', () {
    final composer = HangulComposer(_fixture);
    final cps = ['강', '뷁', '닭', 'ㅋ', '읽', '한'].map(_cp).toList();
    final glyphs = {
      for (final cp in cps)
        cp: FontGlyph(composer.compose(cp)!, FontMetrics.hangulAdvance),
    };
    final info = readTtf(
      buildTtf(
        FontSpec(
          familyName: 't',
          asciiFamilyName: 't',
          created: FontMetrics.fixedCreated,
          glyphs: glyphs,
        ),
      ),
    );
    for (final cp in cps) {
      expect(info.glyph(info.cmap[cp]!).contours, glyphs[cp]!.outline.contours);
    }
  });

  test('픽스처 전체 폰트를 빌드해 검증하고 샘플 이미지를 만든다', () async {
    final composer = HangulComposer(_fixture);
    final sw = Stopwatch()..start();
    final glyphs = {
      for (final cp in _allCodePoints)
        cp: FontGlyph(composer.compose(cp)!, FontMetrics.hangulAdvance),
    };
    final composeMs = sw.elapsedMilliseconds;
    final bytes = buildTtf(
      FontSpec(
        familyName: '회애액 획 픽스처',
        asciiFamilyName: 'HwaeaekStrokeFixture',
        created: FontMetrics.fixedCreated,
        glyphs: glyphs,
      ),
    );
    // ignore: avoid_print
    print(
      '조합 ${composeMs}ms, 전체 ${sw.elapsedMilliseconds}ms, '
      '${(bytes.length / 1048576).toStringAsFixed(2)}MB',
    );
    final out = Directory('../build/poc')..createSync(recursive: true);
    final font = File('${out.path}/stroke_v1.ttf')..writeAsBytesSync(bytes);
    if (!toolsAvailable()) return;
    await validateTtf(font, expectCmap: 11172 + 51 + 1);
    await Process.run(pythonTool.path, [
      '-I',
      '../tools/render_sample.py',
      font.path,
      '${out.path}/stroke_v1.png',
      '다람쥐 헌 쳇바퀴에 타고파',
      '닭 볶음탕 뷁 왠지 꿇어앉아',
      '읽고 밟고 핥고 없어도 넓다',
    ]);
  });
}
