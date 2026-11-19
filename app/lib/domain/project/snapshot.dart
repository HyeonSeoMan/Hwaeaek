/// 프로젝트 글리프 스냅샷과 유효 글리프 (Spec §3.3).
library;

import '../compose/composer.dart';
import '../glyph/glyph.dart';
import '../ink/ink.dart';

enum GlyphSelection { generated, custom }

class FontMetadata {
  const FontMetadata({
    required this.familyName,
    required this.asciiFamilyName,
    this.styleName = 'Regular',
    this.versionMinor = 0,
    this.license = '',
  });

  final String familyName;
  final String asciiFamilyName;
  final String styleName;
  final int versionMinor;
  final String license;
}

/// 커스텀 음절 하나: 선택 상태와 현재 수정본 윤곽선.
class CustomEntry {
  const CustomEntry(this.selection, this.revisionId, this.outline);

  final GlyphSelection selection;
  final int revisionId;
  final GlyphOutline outline;
}

/// 한 시점의 프로젝트 글리프 상태. 불변이며 isolate로 보낼 수 있다.
class GlyphSnapshot {
  const GlyphSnapshot({
    required this.projectId,
    required this.revision,
    required this.baseRevision,
    required this.baseSetVersion,
    required this.memoUnlocked,
    required this.baseStrokes,
    required this.customs,
    required this.metadata,
  });

  final String projectId;

  /// `projects.glyph_revision`.
  final int revision;

  /// `projects.base_revision`.
  final int baseRevision;
  final int baseSetVersion;
  final bool memoUnlocked;
  final Map<String, List<InkStroke>> baseStrokes;
  final Map<int, CustomEntry> customs;
  final FontMetadata metadata;
}

/// 유효 글리프 (PRD FR-05: 선택 상태가 유일한 기준). null이면 조합 오류.
GlyphOutline? effectiveGlyph(
  GlyphSnapshot snapshot,
  GlyphOutline? Function(int cp) compose,
  int cp,
) {
  final c = snapshot.customs[cp];
  if (c != null && c.selection == GlyphSelection.custom) {
    return c.outline.isEmpty ? null : c.outline;
  }
  return compose(cp);
}

/// 조합 결과 LRU 캐시 (Spec §6.5). 기본 글리프가 바뀌면 통째로 새로 만든다.
class CachedComposer {
  CachedComposer(this.composer, {this.capacity = 4000});

  final HangulComposer composer;
  final int capacity;
  // LinkedHashMap 삽입 순서를 LRU 순서로 쓴다. null도 캐시한다(조합 오류).
  final _cache = <int, GlyphOutline?>{};

  int get length => _cache.length;

  GlyphOutline? compose(int cp) {
    if (_cache.containsKey(cp)) {
      final v = _cache.remove(cp);
      _cache[cp] = v;
      return v;
    }
    final v = composer.compose(cp);
    _cache[cp] = v;
    if (_cache.length > capacity) _cache.remove(_cache.keys.first);
    return v;
  }
}
