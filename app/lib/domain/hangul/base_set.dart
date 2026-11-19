/// 기본 글리프 세트 버전 (Spec §3.2). 역할 키는 MVP에서 호환 자모 1자다.
library;

import 'hangul.dart';

const latestBaseSetVersion = 1;

/// 필수 기본 글리프 35자: 기본 자음 14 + 모음 21 (Spec §10 입력 순서).
const _requiredV1 = [
  'ㄱ', 'ㄴ', 'ㄷ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅅ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ', //
  'ㅏ', 'ㅑ', 'ㅓ', 'ㅕ', 'ㅗ', 'ㅛ', 'ㅜ', 'ㅠ', 'ㅡ', 'ㅣ', //
  'ㅐ', 'ㅒ', 'ㅔ', 'ㅖ', //
  'ㅘ', 'ㅙ', 'ㅚ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅢ',
];

/// 필수 기본 글리프 역할 키(입력 순서).
List<String> requiredBaseGlyphs(int version) => switch (version) {
  1 => _requiredV1,
  _ => throw ArgumentError.value(version, 'baseSetVersion'),
};

/// 보강 기본 글리프: 쌍자음 5 + 겹받침 11. 없으면 구성 자음으로 만든다.
List<String> supplementaryBaseGlyphs(int version) => switch (version) {
  1 => compoundConsonants.keys.toList(),
  _ => throw ArgumentError.value(version, 'baseSetVersion'),
};

/// 필수 기본 글리프가 모두 있는지.
bool hasAllRequired(Iterable<String> written, int version) =>
    written.toSet().containsAll(requiredBaseGlyphs(version));
