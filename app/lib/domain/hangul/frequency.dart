/// 음절 빈도 순서 (PRD FR-06, Spec §14).
///
/// 빈도 자산(`syllables.txt`)이 있으면 그 순서, 없으면 KS X 1001 2,350자 순서를
/// 먼저 쓰고 나머지 음절은 Unicode 순서로 붙인다.
library;

import 'hangul.dart';

class FrequencyOrder {
  FrequencyOrder._(this.syllables, this.source)
    : _rank = {for (final (i, cp) in syllables.indexed) cp: i};

  /// 11,172자 전체, 앞일수록 자주 쓰는 음절.
  final List<int> syllables;

  /// 자산 첫 줄의 출처 설명.
  final String source;

  final Map<int, int> _rank;

  /// 정렬용 순위. 음절이 아니면(호환 자모 등) 맨 앞.
  int rankOf(int cp) => _rank[cp] ?? -1;

  /// [codePoints]를 빈도 순으로 정렬한 새 목록.
  List<int> sort(Iterable<int> codePoints) =>
      codePoints.toList()..sort((a, b) => rankOf(a).compareTo(rankOf(b)));

  /// 자산 텍스트(`# 출처` 첫 줄 + 음절 한 줄에 하나)에서 만든다.
  /// 음절이 아니거나 중복인 줄은 무시한다.
  factory FrequencyOrder.parse(String asset) {
    final lines = asset.split('\n');
    final source = lines.isNotEmpty && lines.first.startsWith('#')
        ? lines.first.substring(1).trim()
        : '';
    final seen = <int>{};
    final order = <int>[];
    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('#') || t.runes.length != 1) continue;
      final cp = t.runes.first;
      if (Syllable.isSyllable(cp) && seen.add(cp)) order.add(cp);
    }
    for (var cp = syllableFirst; cp <= syllableLast; cp++) {
      if (seen.add(cp)) order.add(cp);
    }
    return FrequencyOrder._(order, source);
  }
}
