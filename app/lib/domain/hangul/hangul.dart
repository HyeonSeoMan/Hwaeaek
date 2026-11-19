/// 한글 음절 분해와 자모 표.
library;

const syllableFirst = 0xAC00;
const syllableLast = 0xD7A3;
const syllableCount = 11172;
const compatJamoFirst = 0x3131;
const compatJamoLast = 0x3163;

/// 초성 19자 (호환 자모 표기).
const choseong = [
  'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', //
  'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
];

/// 중성 21자.
const jungseong = [
  'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', //
  'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ',
];

/// 종성 28자. 0번은 받침 없음.
const jongseong = [
  '', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', //
  'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', //
  'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
];

/// 겹자음 → 구성 자음. 기본 글리프가 없을 때 나란히 배치해 만든다.
const compoundConsonants = {
  'ㄲ': ('ㄱ', 'ㄱ'),
  'ㄸ': ('ㄷ', 'ㄷ'),
  'ㅃ': ('ㅂ', 'ㅂ'),
  'ㅆ': ('ㅅ', 'ㅅ'),
  'ㅉ': ('ㅈ', 'ㅈ'),
  'ㄳ': ('ㄱ', 'ㅅ'),
  'ㄵ': ('ㄴ', 'ㅈ'),
  'ㄶ': ('ㄴ', 'ㅎ'),
  'ㄺ': ('ㄹ', 'ㄱ'),
  'ㄻ': ('ㄹ', 'ㅁ'),
  'ㄼ': ('ㄹ', 'ㅂ'),
  'ㄽ': ('ㄹ', 'ㅅ'),
  'ㄾ': ('ㄹ', 'ㅌ'),
  'ㄿ': ('ㄹ', 'ㅍ'),
  'ㅀ': ('ㄹ', 'ㅎ'),
  'ㅄ': ('ㅂ', 'ㅅ'),
};

enum VowelShape {
  /// 오른쪽에 서는 모음: ㅏ ㅓ ㅣ …
  vertical,

  /// 아래에 눕는 모음: ㅗ ㅜ ㅡ …
  horizontal,

  /// 아래와 오른쪽을 함께 쓰는 모음: ㅘ ㅝ ㅢ …
  mixed,
}

VowelShape vowelShape(String v) => switch (v) {
  'ㅗ' || 'ㅛ' || 'ㅜ' || 'ㅠ' || 'ㅡ' => VowelShape.horizontal,
  'ㅘ' || 'ㅙ' || 'ㅚ' || 'ㅝ' || 'ㅞ' || 'ㅟ' || 'ㅢ' => VowelShape.mixed,
  _ => VowelShape.vertical,
};

class Syllable {
  const Syllable(this.lead, this.vowel, this.tail);

  final String lead;
  final String vowel;

  /// 받침이 없으면 빈 문자열.
  final String tail;

  bool get hasTail => tail.isNotEmpty;

  static bool isSyllable(int cp) => cp >= syllableFirst && cp <= syllableLast;

  static bool isCompatJamo(int cp) =>
      cp >= compatJamoFirst && cp <= compatJamoLast;

  static Syllable decompose(int cp) {
    assert(isSyllable(cp));
    final s = cp - syllableFirst;
    return Syllable(
      choseong[s ~/ 588],
      jungseong[(s % 588) ~/ 28],
      jongseong[s % 28],
    );
  }
}
