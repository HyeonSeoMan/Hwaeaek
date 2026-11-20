/// 메모 렌더러 상태: 열린 메모 글자만 담은 동적 폰트 (Spec §8.1).
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/font/metrics.dart';
import '../domain/font/ttf_writer.dart';
import '../domain/glyph/latin_set.dart';
import '../domain/hangul/hangul.dart';
import '../infra/platform/dynamic_font.dart';
import 'snapshot.dart';

class MemoFontState {
  const MemoFontState({
    this.family,
    this.loaded = const {},
    this.appliedCmap = const {},
    this.knownErrors = const {},
    this.builtFromRevision = -1,
    this.lastBuildMs = 0,
  });

  /// 지금 적용된 패밀리 이름. 첫 빌드 전에는 null.
  final String? family;
  final Set<int> loaded;
  final Set<int> appliedCmap;

  /// 조합 오류로 알려진 글자 (대체 표시 대상, Spec §8.2).
  final Set<int> knownErrors;
  final int builtFromRevision;
  final int lastBuildMs;
}

typedef MemoFontKey = ({String projectId, String memoId});

/// 텍스트 변경([ensure])과 스냅샷 revision 변경에 따라 다시 빌드한다.
class MemoFontNotifier extends Notifier<MemoFontState> {
  MemoFontNotifier(this.key);

  final MemoFontKey key;

  /// 테스트에서 바꾼다.
  static Future<String> Function(Uint8List bytes) register = registerFont;

  String _text = '';
  var _building = false;
  var _again = false;

  @override
  MemoFontState build() {
    ref.listen(glyphRendererProvider(key.projectId), (_, next) {
      if (next != null &&
          next.snapshot.revision != stateOrNull?.builtFromRevision) {
        _schedule();
      }
    });
    return const MemoFontState();
  }

  /// 메모 텍스트가 바뀔 때 부른다. 조합 중인 글자도 포함한다(FR-07).
  void ensure(String text) {
    _text = text;
    final needed = _needed(text);
    final renderer = ref.read(glyphRendererProvider(key.projectId));
    if (renderer != null &&
        renderer.snapshot.revision == state.builtFromRevision &&
        state.loaded.containsAll(needed)) {
      return;
    }
    _schedule();
  }

  static Set<int> _needed(String text) => {
    for (final r in text.runes)
      if (Syllable.isSyllable(r) || Syllable.isCompatJamo(r) || isLatinGlyph(r))
        r,
  };

  void _schedule() {
    if (!ref.mounted) return;
    if (_building) {
      _again = true;
      return;
    }
    unawaited(_build());
  }

  Future<void> _build() async {
    _building = true;
    try {
      do {
        _again = false;
        final renderer = ref.read(glyphRendererProvider(key.projectId));
        if (renderer == null) return;
        final sw = Stopwatch()..start();
        final want = {...state.loaded, ..._needed(_text)};
        final glyphs = <int, FontGlyph>{};
        for (final cp in want) {
          final g = renderer.outline(cp);
          if (g != null) {
            glyphs[cp] = FontGlyph(
              g,
              advanceFor(cp, g, hangulAdvance: FontMetrics.hangulAdvance),
            );
          }
        }
        final bytes = buildTtf(
          FontSpec(
            familyName: 'hw',
            asciiFamilyName: 'hw',
            created: FontMetrics.fixedCreated,
            glyphs: glyphs,
          ),
        );
        String family;
        try {
          family = await register(bytes);
        } catch (_) {
          // 등록 실패: 상태를 바꾸지 않고 1초 뒤 다시 시도한다.
          Timer(const Duration(seconds: 1), _schedule);
          return;
        }
        if (!ref.mounted) return;
        state = MemoFontState(
          family: family,
          loaded: want,
          appliedCmap: glyphs.keys.toSet(),
          knownErrors: want.difference(glyphs.keys.toSet()),
          builtFromRevision: renderer.snapshot.revision,
          lastBuildMs: sw.elapsedMilliseconds,
        );
      } while (_again);
    } finally {
      _building = false;
    }
  }
}

final memoFontProvider = NotifierProvider.autoDispose
    .family<MemoFontNotifier, MemoFontState, MemoFontKey>(MemoFontNotifier.new);
