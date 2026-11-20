/// 메모 입력 보조: 한글 정규화 포매터와 대체 표시 컨트롤러 (Spec §8.2, §8.3).
library;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/glyph/latin_set.dart';
import '../domain/hangul/hangul.dart';
import '../domain/hangul/normalize.dart';

/// 한글 입력기 조합 중이 아닐 때만(붙여넣기, 조합 완료) 정규화한다.
class HangulNormalizeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return newValue;
    }
    final r = normalizeHangul(newValue.text);
    if (r.text == newValue.text) return newValue;
    final sel = newValue.selection;
    return TextEditingValue(
      text: r.text,
      selection: sel.isValid
          ? TextSelection(
              baseOffset: r.mapOffset(sel.baseOffset),
              extentOffset: r.mapOffset(sel.extentOffset),
            )
          : sel,
    );
  }
}

/// 사용자 폰트에 없는 글자를 회색 + 점선 밑줄로 그린다(NFR-06: 색만으로 구분하지 않음).
class MemoTextController extends TextEditingController {
  MemoTextController({super.text});

  /// 조합 오류이거나 아직 그리지 않은 글자 (MemoFontState.knownErrors).
  Set<int> knownErrors = const {};

  /// 대체 표시 스타일의 색.
  Color fallbackColor = const Color(0xFF8A8A8A);

  /// 사용자 폰트로 그릴 수 없는 글자인지. 한글·호환 자모·영문 세트는 조합 오류나
  /// 아직 그리지 않은 것(knownErrors)만, 그 밖의 문자(이모지 등)는 항상 대체 표시.
  static bool isFallback(int cp, Set<int> knownErrors) {
    if (cp == 0x20 || cp == 0x0A) return false;
    if (Syllable.isSyllable(cp) ||
        Syllable.isCompatJamo(cp) ||
        isLatinGlyph(cp)) {
      return knownErrors.contains(cp);
    }
    return true;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = super.buildTextSpan(
      context: context,
      style: style,
      withComposing: withComposing,
    );
    final fallback = TextStyle(
      color: fallbackColor,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: fallbackColor,
    );
    return TextSpan(style: base.style, children: [_split(base, fallback)]);
  }

  /// [span]의 글자들을 대체 표시 여부로 나눈다(조합 밑줄 등 기존 스타일 유지).
  InlineSpan _split(InlineSpan span, TextStyle fallback) {
    if (span is! TextSpan) return span;
    final children = <InlineSpan>[];
    final text = span.text;
    if (text != null && text.isNotEmpty) {
      final buf = StringBuffer();
      bool? current;
      void flush() {
        if (buf.isEmpty) return;
        children.add(
          TextSpan(text: buf.toString(), style: current! ? fallback : null),
        );
        buf.clear();
      }

      for (final r in text.runes) {
        final f = isFallback(r, knownErrors);
        if (current != null && f != current) flush();
        current = f;
        buf.writeCharCode(r);
      }
      flush();
    }
    for (final c in span.children ?? const <InlineSpan>[]) {
      children.add(_split(c, fallback));
    }
    return TextSpan(style: span.style, children: children);
  }
}
