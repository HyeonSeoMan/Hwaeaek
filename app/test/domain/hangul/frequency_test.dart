import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/domain/hangul/frequency.dart';

int _cp(String s) => s.runes.first;

void main() {
  final ksx = FrequencyOrder.parse(File('assets/frequency/ksx1001.txt').readAsStringSync());

  test('KS X 1001 2,350자가 먼저, 나머지는 Unicode 순서로 11,172자 전체', () {
    expect(ksx.syllables, hasLength(11172));
    expect(ksx.syllables.toSet(), hasLength(11172));
    expect(ksx.syllables.first, _cp('가'));
    expect(ksx.syllables[2349], _cp('힝'));
    expect(ksx.syllables[2350], _cp('갂')); // KS X 1001에 없는 첫 음절
    expect(ksx.source, startsWith('source=KS X 1001'));
  });

  test('정렬: 자주 쓰는 순서, 호환 자모는 맨 앞', () {
    expect(ksx.sort([_cp('갂'), _cp('힝'), _cp('가'), _cp('ㅎ')]),
        [_cp('ㅎ'), _cp('가'), _cp('힝'), _cp('갂')]);
  });

  test('빈 줄·주석·음절이 아닌 줄·중복은 무시한다', () {
    final o = FrequencyOrder.parse('# source=test\n나\n\nab\n나\nㄱ\n가\n');
    expect(o.syllables.take(2), [_cp('나'), _cp('가')]);
    expect(o.syllables, hasLength(11172));
    expect(o.source, 'source=test');
  });
}
