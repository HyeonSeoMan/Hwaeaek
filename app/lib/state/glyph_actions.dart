/// 글리프 쓰기 동작과 실행 취소 슬롯 (Spec §4.3, §9.1).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/ink/ink.dart';
import '../infra/db/glyph_dao.dart';
import 'pending_writes.dart';
import 'providers.dart';

/// 실행 취소 슬롯 하나. 대상 쓰기가 커밋되기 전에는 [change]가 null이다.
class UndoEntry {
  UndoEntry(this.writeKey, this.projectId, this.codePoint);

  final String writeKey;
  final String projectId;
  final int codePoint;
  SelectionChange? change;
}

enum UndoResult { undone, cancelledPending, notPossible }

class UndoNotifier extends Notifier<UndoEntry?> {
  @override
  UndoEntry? build() => null;

  void record(UndoEntry entry) => state = entry;

  /// 스낵바가 사라질 때, 커스텀 삭제, 프로젝트 전환·삭제 때 비운다.
  void clear() => state = null;

  Future<UndoResult> undo() async {
    final entry = state;
    state = null;
    if (entry == null) return UndoResult.notPossible;
    final writes = ref.read(pendingWritesProvider);
    if (writes.isPending(entry.writeKey)) {
      writes.cancel(entry.writeKey);
      return UndoResult.cancelledPending;
    }
    final change = entry.change;
    if (change == null) return UndoResult.notPossible;
    final ok = await ref.read(glyphDaoProvider).undo(change);
    return ok ? UndoResult.undone : UndoResult.notPossible;
  }
}

final undoProvider = NotifierProvider<UndoNotifier, UndoEntry?>(
  UndoNotifier.new,
);

/// 한 프로젝트의 글리프 쓰기. 모든 쓰기는 대기 목록을 거친다(FR-01).
class GlyphActions {
  GlyphActions(this.ref, this.projectId);

  final Ref ref;
  final String projectId;

  GlyphDao get _dao => ref.read(glyphDaoProvider);
  PendingWrites get _writes => ref.read(pendingWritesProvider);
  UndoNotifier get _undo => ref.read(undoProvider.notifier);

  String baseKey(String roleKey) => 'base:$projectId:$roleKey';
  String customKey(int cp) => 'custom:$projectId:$cp';

  Future<void> saveBaseGlyph(String roleKey, List<InkStroke> strokes) =>
      _writes.run(
        baseKey(roleKey),
        WriteKind.glyph,
        () => _dao.saveBaseGlyph(projectId, roleKey, strokes),
      );

  /// 커스텀 글리프 저장: 기본 펜으로 윤곽선을 굳힌다(Spec §3.1).
  Future<void> saveCustom(int cp, List<InkStroke> strokes) => _undoable(
    cp,
    () => _dao.saveCustom(
      projectId,
      cp,
      strokes,
      strokesToOutline(strokes),
      PenStyle.base,
    ),
  );

  Future<void> revertToGenerated(int cp) =>
      _undoable(cp, () => _dao.revertToGenerated(projectId, cp));

  Future<void> reselectCustom(int cp) =>
      _undoable(cp, () => _dao.reselectCustom(projectId, cp));

  Future<void> setCurrentRevision(int cp, int revisionId) =>
      _undoable(cp, () => _dao.setCurrentRevision(projectId, cp, revisionId));

  Future<void> deleteCustom(int cp) {
    _undo.clear();
    return _writes.run(
      customKey(cp),
      WriteKind.glyph,
      () => _dao.deleteCustom(projectId, cp),
    );
  }

  Future<void> _undoable(int cp, Future<SelectionChange?> Function() write) {
    final entry = UndoEntry(customKey(cp), projectId, cp);
    _undo.record(entry);
    return _writes.run(entry.writeKey, WriteKind.glyph, () async {
      entry.change = await write();
    });
  }
}

final glyphActionsProvider = Provider.family<GlyphActions, String>(
  GlyphActions.new,
);
