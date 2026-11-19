/// 프로젝트의 글리프 상태와 앱 안 표시용 동적 폰트 (PRD FR-04, FR-05, FR-07).
///
/// PoC: 저장소 없이 메모리에만 둔다.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../font/glyph.dart';
import '../font/ttf_writer.dart';
import '../hangul/composer.dart';
import '../hangul/hangul.dart';
import '../ink/ink.dart';

enum GlyphSource { generated, custom }

class CustomGlyph {
  CustomGlyph();

  /// 수정 이력. 지우지 않고 추가만 한다(POL-01).
  final revisions = <List<InkStroke>>[];
  final outlines = <GlyphOutline>[];
  int current = -1;

  GlyphOutline get currentOutline => outlines[current];
}

/// 실행 취소용 스냅샷: 한 음절의 선택 상태와 현재 수정본.
class _UndoEntry {
  const _UndoEntry(this.cp, this.selection, this.current);

  final int cp;
  final GlyphSource selection;
  final int current;
}

class FontSession extends ChangeNotifier {
  FontSession(Map<String, BaseGlyph> baseGlyphs)
    : _baseGlyphs = Map.of(baseGlyphs) {
    _composer = HangulComposer(_baseGlyphs, rule: _rule);
  }

  static const ascender = 800;
  static const descender = -200;

  final Map<String, BaseGlyph> _baseGlyphs;
  var _rule = CompositionRule.strokeScale;
  late HangulComposer _composer;
  final _custom = <int, CustomGlyph>{};
  final _selection = <int, GlyphSource>{};
  _UndoEntry? _undo;

  // 동적 폰트 상태
  final _loaded = <int>{};
  var _generation = 0;
  var _appliedGeneration = 0;
  String? _family;
  var _dirty = true;
  Future<void>? _pending;

  /// 마지막 동적 폰트 빌드 측정값 (PoC 계측).
  String lastBuildInfo = '';

  String? get fontFamily => _family;

  Map<String, BaseGlyph> get baseGlyphs => Map.unmodifiable(_baseGlyphs);

  CompositionRule get rule => _rule;

  set rule(CompositionRule value) {
    _rule = value;
    _rebuildComposer();
  }

  /// 기본 글리프 세트를 통째로 바꾼다 (PoC 픽스처 전환).
  void replaceBaseGlyphs(Map<String, BaseGlyph> glyphs) {
    _baseGlyphs
      ..clear()
      ..addAll(glyphs);
    _rebuildComposer();
  }

  GlyphSource selectionOf(int cp) => _selection[cp] ?? GlyphSource.generated;

  CustomGlyph? customOf(int cp) => _custom[cp];

  bool get canUndo => _undo != null;

  /// 유효 글리프 (FR-05: 선택 상태가 유일한 기준). 없으면 조합 오류.
  GlyphOutline? effectiveGlyph(int cp) {
    if (selectionOf(cp) == GlyphSource.custom) {
      return _custom[cp]!.currentOutline;
    }
    return _composer.compose(cp);
  }

  // ---- 편집 ----

  void setBaseGlyph(String jamo, List<InkStroke> strokes) {
    _baseGlyphs[jamo] = BaseGlyph.strokes(strokes);
    _rebuildComposer();
  }

  void _rebuildComposer() {
    _composer = HangulComposer(_baseGlyphs, rule: _rule);
    _invalidate();
  }

  /// 커스텀 글리프 저장: 새 수정본 추가 후 선택 상태를 custom으로.
  void saveCustom(int cp, List<InkStroke> strokes) {
    _remember(cp);
    final c = _custom.putIfAbsent(cp, CustomGlyph.new);
    c.revisions.add(strokes);
    c.outlines.add(strokesToOutline(strokes));
    c.current = c.revisions.length - 1;
    _selection[cp] = GlyphSource.custom;
    _invalidate();
  }

  void revertToGenerated(int cp) {
    if (selectionOf(cp) != GlyphSource.custom) return;
    _remember(cp);
    _selection[cp] = GlyphSource.generated;
    _invalidate();
  }

  void reselectCustom(int cp) {
    if (_custom[cp] == null) return;
    _remember(cp);
    _selection[cp] = GlyphSource.custom;
    _invalidate();
  }

  void undo() {
    final u = _undo;
    if (u == null) return;
    _undo = null;
    _selection[u.cp] = u.selection;
    final c = _custom[u.cp];
    if (c != null && u.current >= 0) c.current = u.current;
    _invalidate();
  }

  void _remember(int cp) {
    _undo = _UndoEntry(cp, selectionOf(cp), _custom[cp]?.current ?? -1);
  }

  void _invalidate() {
    _dirty = true;
    notifyListeners();
  }

  // ---- 동적 폰트 (메모 표시용) ----

  /// [text]에 필요한 음절·자모가 모두 담긴 폰트를 준비한다. 새 글자가 있거나
  /// 글리프가 바뀌었으면 새 패밀리 이름으로 다시 빌드해 등록한다.
  Future<void> ensureFontFor(String text) {
    final needed = <int>{
      for (final r in text.runes)
        if (Syllable.isSyllable(r) || Syllable.isCompatJamo(r)) r,
    };
    if (!_dirty && _loaded.containsAll(needed)) return _pending ?? Future.value();
    _loaded.addAll(needed);
    _dirty = false;
    return _pending = _rebuild();
  }

  Future<void> _rebuild() async {
    final generation = ++_generation;
    final sw = Stopwatch()..start();
    final glyphs = <int, FontGlyph>{};
    for (final cp in _loaded) {
      final g = effectiveGlyph(cp);
      if (g != null) glyphs[cp] = FontGlyph(g, 1000);
    }
    final bytes = buildTtf(
      FontSpec(
        familyName: 'hw',
        asciiFamilyName: 'hw',
        ascender: ascender,
        descender: descender,
        glyphs: glyphs,
      ),
    );
    final buildMs = sw.elapsedMilliseconds;
    // 같은 이름 재등록은 캐시 문제가 있으므로 빌드마다 새 패밀리 이름을 쓴다.
    final family = 'hw_$generation';
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    // 늦게 끝난 이전 빌드가 최신 폰트를 덮어쓰지 않게 한다.
    if (generation < _appliedGeneration) return;
    _appliedGeneration = generation;
    _family = family;
    lastBuildInfo =
        '${glyphs.length}자 · 빌드 ${buildMs}ms · 등록 '
        '${sw.elapsedMilliseconds - buildMs}ms';
    notifyListeners();
  }

  // ---- 내보내기 (FR-08) ----

  ({Uint8List bytes, int excluded}) buildFullFont({required int exportCount}) {
    final glyphs = <int, FontGlyph>{};
    var excluded = 0;
    for (final range in [
      (compatJamoFirst, compatJamoLast),
      (syllableFirst, syllableLast),
    ]) {
      for (var cp = range.$1; cp <= range.$2; cp++) {
        final g = effectiveGlyph(cp);
        if (g == null || g.isEmpty) {
          excluded++;
        } else {
          glyphs[cp] = FontGlyph(g, 1000);
        }
      }
    }
    final bytes = buildTtf(
      FontSpec(
        familyName: '회애액 내 손글씨',
        asciiFamilyName: 'Hwaeaek-Poc',
        versionMinor: exportCount,
        ascender: ascender,
        descender: descender,
        glyphs: glyphs,
      ),
    );
    return (bytes: bytes, excluded: excluded);
  }
}
