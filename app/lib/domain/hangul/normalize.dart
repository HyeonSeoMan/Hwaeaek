/// 한글 정규화 (PRD FR-07, Spec §8.3): 현대 첫가끝 자모 L V (T)를 완성형 음절로
/// 합친다. 그 밖의 문자(옛한글 자모 포함)는 그대로 둔다.
library;

const _lFirst = 0x1100, _lLast = 0x1112;
const _vFirst = 0x1161, _vLast = 0x1175;
const _tFirst = 0x11A8, _tLast = 0x11C2;

bool _isL(int c) => c >= _lFirst && c <= _lLast;
bool _isV(int c) => c >= _vFirst && c <= _vLast;
bool _isT(int c) => c >= _tFirst && c <= _tLast;

/// 정규화한 문자열과, 원래 UTF-16 오프셋 → 새 오프셋 변환 함수.
({String text, int Function(int) mapOffset}) normalizeHangul(String input) {
  final units = input.codeUnits;
  final out = StringBuffer();
  // oldToNew[i] = 원래 오프셋 i가 새 문자열에서 가리킬 오프셋.
  final oldToNew = List<int>.filled(units.length + 1, 0);
  var i = 0;
  var n = 0;
  while (i < units.length) {
    final c = units[i];
    if (_isL(c) && i + 1 < units.length && _isV(units[i + 1])) {
      final hasT = i + 2 < units.length && _isT(units[i + 2]);
      final t = hasT ? units[i + 2] - 0x11A7 : 0;
      out.writeCharCode(
        0xAC00 + ((c - _lFirst) * 21 + (units[i + 1] - _vFirst)) * 28 + t,
      );
      final len = hasT ? 3 : 2;
      for (var k = 0; k < len; k++) {
        oldToNew[i + k] = n;
      }
      i += len;
      n += 1;
      continue;
    }
    out.writeCharCode(c);
    oldToNew[i] = n;
    i += 1;
    n += 1;
  }
  oldToNew[units.length] = n;
  return (
    text: out.toString(),
    mapOffset: (o) => oldToNew[o.clamp(0, units.length)],
  );
}
