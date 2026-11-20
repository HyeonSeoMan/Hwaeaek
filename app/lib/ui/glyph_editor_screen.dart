/// 글리프 편집 화면 (PRD FR-02, FR-05, Spec §5). 기본·커스텀 공용.
library;

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/compose/composer.dart';
import '../domain/font/metrics.dart';
import '../domain/glyph/glyph.dart';
import '../domain/glyph/latin_set.dart';
import '../domain/ink/hws1.dart';
import '../domain/ink/ink.dart';
import '../domain/ink/quantize.dart';
import '../infra/db/glyph_dao.dart';
import '../infra/db/memo_dao.dart';
import '../state/pending_writes.dart';
import '../state/providers.dart';
import 'glyph_painter.dart';

class GlyphEditorArgs {
  const GlyphEditorArgs({
    required this.projectId,
    required this.title,
    required this.draftKind,
    required this.draftKey,
    required this.onSave,
    this.reference,
    this.guideJamo,
    this.initialStrokes = const [],
    this.trailing,
  });

  final String projectId;
  final String title;
  final DraftKind draftKind;
  final String draftKey;

  /// 저장. 커밋될 때 끝난다(실패하면 대기 목록이 재시도한다).
  final Future<void> Function(List<InkStroke> strokes) onSave;

  /// 흐리게 보여 줄 현재 글리프(덧그리기).
  final GlyphOutline? reference;

  /// 기본 글리프 편집이면 그 자모. 배치 영역 가이드를 그린다.
  final String? guideJamo;

  /// 초안이 없을 때 시작할 획(기존 기본 글리프).
  final List<InkStroke> initialStrokes;

  /// 앱바에 더 넣을 버튼(수정 이력 등).
  final Widget? trailing;
}

enum _Tool { pen, eraser }

class GlyphEditorScreen extends ConsumerStatefulWidget {
  const GlyphEditorScreen(this.args, {super.key});

  final GlyphEditorArgs args;

  @override
  ConsumerState<GlyphEditorScreen> createState() => _GlyphEditorScreenState();
}

class _GlyphEditorScreenState extends ConsumerState<GlyphEditorScreen> {
  var _strokes = <InkStroke>[];
  final _undo = <List<InkStroke>>[];
  final _redo = <List<InkStroke>>[];
  final _outlineCache = Map<InkStroke, Contour?>.identity();
  List<InkPoint>? _current;
  int? _activePointer;
  var _activeIsStylus = false;
  var _stylusSeen = false;
  var _drawWithFinger = false;
  var _tool = _Tool.pen;
  var _showReference = true;
  var _saving = false;
  var _dirty = false;
  var _loaded = false;
  Duration? _strokeStart;

  GlyphEditorArgs get a => widget.args;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final draft = await ref
        .read(glyphDaoProvider)
        .loadDraft(a.projectId, a.draftKind, a.draftKey);
    final finger = await ref
        .read(settingsDaoProvider)
        .getBool(SettingsDao.drawWithFinger);
    if (!mounted) return;
    setState(() {
      // 초안이 있으면 묻지 않고 이어서 연다(Spec §4.4).
      _strokes = draft ?? List.of(a.initialStrokes);
      _dirty = draft != null;
      _drawWithFinger = finger;
      _loaded = true;
    });
  }

  int get _pointCount => _strokes.fold(0, (n, s) => n + s.points.length);

  // ---- 편집 기록 ----

  void _commit(List<InkStroke> next) {
    _undo.add(_strokes);
    _redo.clear();
    setState(() {
      _strokes = next;
      _dirty = true;
    });
    _saveDraft();
  }

  void _saveDraft() {
    final strokes = List.of(_strokes);
    unawaited(
      ref
          .read(pendingWritesProvider)
          .run(
            'draft:${a.projectId}:${a.draftKind.name}:${a.draftKey}',
            WriteKind.draft,
            () => ref
                .read(glyphDaoProvider)
                .saveDraft(a.projectId, a.draftKind, a.draftKey, strokes),
          ),
    );
  }

  void _undoStep() {
    if (_undo.isEmpty) return;
    _redo.add(_strokes);
    setState(() => _strokes = _undo.removeLast());
    _saveDraft();
  }

  void _redoStep() {
    if (_redo.isEmpty) return;
    _undo.add(_strokes);
    setState(() => _strokes = _redo.removeLast());
    _saveDraft();
  }

  // ---- 입력 (Spec §5) ----

  bool _accepts(PointerEvent e) {
    if (e.kind == PointerDeviceKind.stylus ||
        e.kind == PointerDeviceKind.invertedStylus) {
      return true;
    }
    return _drawWithFinger || !_stylusSeen;
  }

  InkPoint _point(PointerEvent e, double side) {
    final stylus = e.kind == PointerDeviceKind.stylus;
    final pressure = stylus && e.pressureMax > e.pressureMin
        ? ((e.pressure - e.pressureMin) / (e.pressureMax - e.pressureMin))
              .clamp(0.0, 1.0)
        : null;
    _strokeStart ??= e.timeStamp;
    return quantizedPoint(
      e.localPosition.dx / side * FontMetrics.unitsPerEm,
      FontMetrics.ascender - e.localPosition.dy / side * FontMetrics.unitsPerEm,
      pressure: pressure,
      tilt: stylus ? e.tilt : null,
      orientation: stylus ? e.orientation : null,
      t: (e.timeStamp - _strokeStart!).inMilliseconds,
    );
  }

  void _down(PointerDownEvent e, double side) {
    final stylus =
        e.kind == PointerDeviceKind.stylus ||
        e.kind == PointerDeviceKind.invertedStylus;
    if (stylus) _stylusSeen = true;
    if (!_accepts(e)) return;
    if (_activePointer != null) {
      // 손바닥 방지: 진행 중인 touch 획은 stylus가 오면 취소한다.
      if (!stylus || _activeIsStylus) return;
      _current = null;
    }
    if (_tool == _Tool.eraser) {
      _erase(e.localPosition, side);
      return;
    }
    if (_strokes.length >= InkLimits.maxStrokes ||
        _pointCount >= InkLimits.maxPointsPerGlyph) {
      _limitReached();
      return;
    }
    _activePointer = e.pointer;
    _activeIsStylus = stylus;
    _strokeStart = null;
    setState(() => _current = [_point(e, side)]);
  }

  void _move(PointerMoveEvent e, double side) {
    if (e.pointer != _activePointer || _current == null) return;
    if (_current!.length >= InkLimits.maxPointsPerStroke ||
        _pointCount + _current!.length >= InkLimits.maxPointsPerGlyph) {
      _finish();
      return;
    }
    setState(() => _current!.add(_point(e, side)));
  }

  void _finish() {
    final c = _current;
    _current = null;
    _activePointer = null;
    if (c == null || c.isEmpty) return;
    _commit([..._strokes, InkStroke(c)]);
  }

  void _cancel() {
    _activePointer = null;
    setState(() => _current = null);
  }

  void _erase(Offset at, double side) {
    for (var i = _strokes.length - 1; i >= 0; i--) {
      final contour = _contour(_strokes[i]);
      if (contour == null) continue;
      final path = outlineToPath(GlyphOutline([contour]), side);
      if (path.contains(at)) {
        _commit([..._strokes]..removeAt(i));
        return;
      }
    }
  }

  void _limitReached() => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text('더 그릴 수 없습니다. 획을 지우고 다시 그려 주세요.')),
    );

  Contour? _contour(InkStroke s) =>
      _outlineCache.putIfAbsent(s, () => strokeToContour(s, PenStyle.base));

  bool get _canSave {
    if (_strokes.isEmpty || _saving) return false;
    double? x0, y0, x1, y1;
    for (final s in _strokes) {
      for (final p in s.points) {
        x0 = x0 == null || p.x < x0 ? p.x : x0;
        y0 = y0 == null || p.y < y0 ? p.y : y0;
        x1 = x1 == null || p.x > x1 ? p.x : x1;
        y1 = y1 == null || p.y > y1 ? p.y : y1;
      }
    }
    // 점 하나 같은 퇴화 글리프는 저장하지 않는다(Spec §6.2).
    return x1! - x0! >= 1 || y1! - y0! >= 1;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await a.onSave(List.of(_strokes));
    if (mounted) Navigator.pop(context, true);
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('저장하지 않은 획이 있습니다'),
        content: const Text('버리면 초안도 지워집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속 편집'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('버리기'),
          ),
        ],
      ),
    );
    if (discard ?? false) {
      await ref
          .read(glyphDaoProvider)
          .discardDraft(a.projectId, a.draftKind, a.draftKey);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final writes = ref.watch(pendingWritesProvider);
    final pendingSave = _saving && writes.banner != WriteBanner.none;
    return PopScope(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _saving) return;
        if (await _confirmLeave() && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(a.title),
          actions: [
            IconButton(
              tooltip: '펜',
              isSelected: _tool == _Tool.pen,
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _tool = _Tool.pen),
            ),
            IconButton(
              tooltip: '지우개 (획을 눌러 지우기)',
              isSelected: _tool == _Tool.eraser,
              icon: const Icon(Icons.auto_fix_normal),
              onPressed: () => setState(() => _tool = _Tool.eraser),
            ),
            IconButton(
              tooltip: '실행 취소',
              icon: const Icon(Icons.undo),
              onPressed: _undo.isEmpty ? null : _undoStep,
            ),
            IconButton(
              tooltip: '다시 실행',
              icon: const Icon(Icons.redo),
              onPressed: _redo.isEmpty ? null : _redoStep,
            ),
            IconButton(
              tooltip: '모두 지우기',
              icon: const Icon(Icons.delete_outline),
              onPressed: _strokes.isEmpty ? null : () => _commit(const []),
            ),
            if (a.reference != null)
              IconButton(
                tooltip: '기존 글리프 보기',
                icon: Icon(
                  _showReference ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _showReference = !_showReference),
              ),
            ?a.trailing,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                child: Text(pendingSave ? '저장 중…' : '저장'),
              ),
            ),
          ],
        ),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final side = (box.biggest.shortestSide - 32).clamp(
                      200.0,
                      760.0,
                    );
                    final live = [
                      ..._strokes,
                      if (_current != null) InkStroke(List.of(_current!)),
                    ];
                    return SizedBox.square(
                      dimension: side,
                      child: Listener(
                        key: const Key('glyph-canvas'),
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (e) => _down(e, side),
                        onPointerMove: (e) => _move(e, side),
                        onPointerUp: (e) {
                          if (e.pointer == _activePointer) _finish();
                        },
                        onPointerCancel: (e) {
                          if (e.pointer == _activePointer) _cancel();
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              painter: _GuidePainter(
                                Theme.of(context).colorScheme,
                                a.guideJamo,
                              ),
                            ),
                            if (_showReference && a.reference != null)
                              CustomPaint(
                                painter: GlyphPainter(
                                  a.reference,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.12),
                                ),
                              ),
                            CustomPaint(
                              painter: GlyphPainter(
                                GlyphOutline([
                                  for (final s in live)
                                    ?(identical(s, live.lastOrNull) &&
                                            _current != null
                                        ? strokeToContour(s, PenStyle.base)
                                        : _contour(s)),
                                ]),
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

/// 글자 몸 상자(캔버스 테두리), 기준선, 조합 영역, 배치 영역 (Spec §5).
/// 영문·숫자는 조합 영역 대신 대문자·소문자 높이와 내림 선.
class _GuidePainter extends CustomPainter {
  _GuidePainter(this.colors, this.jamo);

  final ColorScheme colors;
  final String? jamo;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / FontMetrics.unitsPerEm;
    double y(num fy) => (FontMetrics.ascender - fy) * s;
    double x(num fx) => fx * s;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = colors.surfaceContainerLow,
    );
    final line = Paint()
      ..color = colors.outlineVariant
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    // 글자 몸 상자
    canvas.drawRect(Offset.zero & size, line);
    // 기준선
    canvas.drawLine(Offset(0, y(0)), Offset(size.width, y(0)), line);
    final j = jamo;
    if (j != null && isLatinGlyph(j.runes.first)) {
      // 영문·숫자: 대문자 높이, 소문자 높이, 내림 선 (조합 영역 없음).
      final guide = Paint()
        ..color = colors.primary.withValues(alpha: 0.35)
        ..strokeWidth = 1;
      for (final fy in [
        LatinGuides.capHeight,
        LatinGuides.xHeight,
        LatinGuides.descender,
      ]) {
        canvas.drawLine(Offset(0, y(fy)), Offset(size.width, y(fy)), guide);
      }
      return;
    }
    // 조합 영역 (보조선)
    final area = Rect.fromLTRB(
      x(CompositionArea.left),
      y(CompositionArea.top),
      x(CompositionArea.right),
      y(CompositionArea.bottom),
    );
    canvas.drawRect(
      area,
      line..color = colors.outlineVariant.withValues(alpha: 0.5),
    );
    // 배치 영역
    if (j != null) {
      final slot = HangulComposer.guideSlotFor(j);
      final w = area.width, h = area.height;
      canvas.drawRect(
        Rect.fromLTRB(
          area.left + slot.x0 * w,
          area.bottom - slot.y1 * h,
          area.left + slot.x1 * w,
          area.bottom - slot.y0 * h,
        ),
        Paint()..color = colors.primary.withValues(alpha: 0.06),
      );
    }
  }

  @override
  bool shouldRepaint(_GuidePainter old) =>
      old.jamo != jamo || old.colors != colors;
}
