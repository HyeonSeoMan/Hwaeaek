import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/domain/hangul/normalize.dart';

String _s(List<int> cps) => String.fromCharCodes(cps);

void main() {
  // Spec §8.3 테스트 벡터 (코드포인트).
  final vectors = <(List<int>, List<int>, String)>[
    ([0x1100, 0x1161, 0x11BC], [0xAC15], 'L V T'),
    ([0x1100, 0x1161], [0xAC00], 'L V'),
    ([0x1100], [0x1100], 'L 단독 그대로'),
    ([0x1100, 0x1161, 0x1100, 0x1161], [0xAC00, 0xAC00], '연속'),
    ([0x61, 0x1112, 0x1161, 0x11AB], [0x61, 0xD55C], '앞 문자 유지'),
    ([0x1100, 0x1176], [0x1100, 0x1176], '옛한글 V 그대로'),
  ];

  for (final (input, output, name) in vectors) {
    test('한글 정규화: $name', () {
      expect(normalizeHangul(_s(input)).text.runes.toList(), output);
    });
  }

  test('오프셋 변환: 합쳐진 글자 뒤 커서', () {
    final r = normalizeHangul(_s([0x61, 0x1112, 0x1161, 0x11AB, 0x62]));
    expect(r.mapOffset(0), 0);
    expect(r.mapOffset(4), 2); // 'b' 앞
    expect(r.mapOffset(5), 3); // 끝
  });
}
