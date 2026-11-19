/// 폰트 이름 규칙 (Spec §3.2, §7.1).
library;

const _psBanned = '[](){}<>/%';

/// name ID 6 규칙: 인쇄 가능한 ASCII(33~126)에서 `[](){}<>/%`·공백을 지우고 63자로 자른다.
String postScriptName(String s) {
  final buf = StringBuffer();
  for (final r in s.runes) {
    if (r >= 33 && r <= 126 && !_psBanned.contains(String.fromCharCode(r))) {
      buf.writeCharCode(r);
    }
  }
  final out = buf.toString();
  return out.length > 63 ? out.substring(0, 63) : out;
}

/// 사용자가 바꾸는 ASCII 패밀리 이름 검사. 문제가 없으면 null, 있으면 이유.
String? asciiFamilyNameError(String name) {
  if (name.isEmpty || name.length > 31) return '1~31자여야 합니다';
  for (final r in name.runes) {
    final ok = r == 0x20 ||
        (r >= 33 && r <= 126 && !_psBanned.contains(String.fromCharCode(r)));
    if (!ok) return '영문, 숫자, 일부 기호만 쓸 수 있습니다';
  }
  if (postScriptName(name).isEmpty) return '영문이나 숫자를 하나 이상 넣어 주세요';
  return null;
}
