/// 숫자·문장부호·영문 글리프 (PRD OQ-04 결정, Spec §3.2).
///
/// 한글과 달리 조합하지 않고 사용자가 그린 획을 그대로 한 글자로 쓴다. 모두
/// 선택이며(메모 잠금 조건이 아님), 폭은 그린 모양에 맞춘 비례폭이다.
library;

import 'glyph.dart';

const latinDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

/// 한글 문장에 자주 쓰는 문장부호. iOS 스마트 따옴표(‘ ’ “ ”)도 넣는다.
const latinPunctuation = [
  '.', ',', '!', '?', "'", '"', '(', ')', '-', '~', ':', ';', //
  '…', '·', '/', '%', '&', '@', '#', '*', '+', '=', //
  '‘', '’', '“', '”',
];

final latinUpper = [for (var c = 0x41; c <= 0x5A; c++) String.fromCharCode(c)];
final latinLower = [for (var c = 0x61; c <= 0x7A; c++) String.fromCharCode(c)];

/// 그리는 순서대로 묶은 그룹.
final latinGroups = <(String, List<String>)>[
  ('숫자', latinDigits),
  ('문장부호', latinPunctuation),
  ('영문 대문자', latinUpper),
  ('영문 소문자', latinLower),
];

final _latinCodePoints = {
  for (final (_, chars) in latinGroups)
    for (final c in chars) c.runes.single,
};

/// 내보내기 순서(코드포인트 오름차순).
final latinCodePoints = _latinCodePoints.toList()..sort();

bool isLatinGlyph(int cp) => _latinCodePoints.contains(cp);

/// 영문 편집 가이드 (폰트 단위, y 위).
abstract final class LatinGuides {
  static const capHeight = 680;
  static const xHeight = 460;
  static const descender = -180;

  /// 글자 양옆 여백. 그린 윤곽선을 왼쪽 여백에 맞추고 폭을 계산한다.
  static const sideBearing = 60;

  /// 너무 좁은 글자(., ' 등)의 최소 폭.
  static const minAdvance = 200;
}

/// 그린 윤곽선을 왼쪽 여백에 맞춰 옮긴다. 폭이 [LatinGuides.minAdvance]보다
/// 좁은 글자(., ' 등)는 최소 폭 안에서 가운데에 둔다. 빈 윤곽선은 그대로.
GlyphOutline alignLatin(GlyphOutline outline) {
  final b = outline.bounds;
  if (b == null) return outline;
  final width = b.xMax - b.xMin;
  final advance = width + 2 * LatinGuides.sideBearing;
  final left = advance < LatinGuides.minAdvance
      ? (LatinGuides.minAdvance - width) ~/ 2
      : LatinGuides.sideBearing;
  return outline.transformed(dx: left - b.xMin);
}

/// [alignLatin]한 윤곽선의 advance width.
int latinAdvance(GlyphOutline aligned) {
  final b = aligned.bounds;
  if (b == null) return LatinGuides.minAdvance;
  final width = b.xMax + LatinGuides.sideBearing;
  return width < LatinGuides.minAdvance ? LatinGuides.minAdvance : width;
}

/// 글자의 advance width: 한글·호환 자모는 고정폭, 그 밖은 [latinAdvance].
int advanceFor(int cp, GlyphOutline outline, {required int hangulAdvance}) =>
    isLatinGlyph(cp) ? latinAdvance(outline) : hangulAdvance;
