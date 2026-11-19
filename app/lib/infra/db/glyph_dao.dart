/// 기본 글리프, 커스텀 글리프, 초안 쓰기 (Spec §4.3, §4.4, §9.1).
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/glyph/glyph.dart';
import '../../domain/glyph/hwo1.dart';
import '../../domain/hangul/base_set.dart';
import '../../domain/ink/hws1.dart';
import '../../domain/ink/ink.dart';
import 'database.dart';
import 'project_dao.dart';

enum GlyphSelection { generated, custom }

/// 음절 하나의 커스텀 상태. 행이 없으면 null로 나타낸다.
class CustomState {
  const CustomState(this.selection, this.revisionId);

  final GlyphSelection selection;
  final int revisionId;

  @override
  bool operator ==(Object other) =>
      other is CustomState &&
      other.selection == selection &&
      other.revisionId == revisionId;

  @override
  int get hashCode => Object.hash(selection, revisionId);

  @override
  String toString() => 'CustomState(${selection.name}, $revisionId)';
}

/// 실행 취소 슬롯에 넣을 변경 (Spec §9.1). [before]가 null이면 첫 저장.
class SelectionChange {
  const SelectionChange(
    this.projectId,
    this.codePoint,
    this.before,
    this.after,
  );

  final String projectId;
  final int codePoint;
  final CustomState? before;
  final CustomState after;
}

enum DraftKind { base, custom }

class GlyphDao {
  GlyphDao(this.db, {Clock? clock}) : now = clock ?? systemClock;

  final AppDatabase db;
  final Clock now;

  // ---- 기본 글리프 ----

  Future<Map<String, List<InkStroke>>> baseGlyphs(String projectId) async {
    final rows = await (db.select(
      db.baseGlyphs,
    )..where((b) => b.projectId.equals(projectId))).get();
    return {for (final r in rows) r.roleKey: decodeHws1(r.strokes)};
  }

  /// 기본 글리프 저장. 필수가 처음 다 차면 `memo_unlocked_at`을 기록한다.
  Future<void> saveBaseGlyph(
    String projectId,
    String roleKey,
    List<InkStroke> strokes,
  ) => db.transaction(() async {
    final t = now();
    await db
        .into(db.baseGlyphs)
        .insertOnConflictUpdate(
          BaseGlyphsCompanion.insert(
            projectId: projectId,
            roleKey: roleKey,
            strokes: encodeHws1(strokes),
            updatedAt: t,
          ),
        );
    final project = await (db.select(
      db.projects,
    )..where((p) => p.id.equals(projectId))).getSingle();
    var unlockedAt = project.memoUnlockedAt;
    if (unlockedAt == null) {
      final keys =
          await (db.selectOnly(db.baseGlyphs)
                ..addColumns([db.baseGlyphs.roleKey])
                ..where(db.baseGlyphs.projectId.equals(projectId)))
              .map((r) => r.read(db.baseGlyphs.roleKey)!)
              .get();
      if (hasAllRequired(keys, project.baseSetVersion)) unlockedAt = t;
    }
    await (db.update(db.projects)..where((p) => p.id.equals(projectId))).write(
      ProjectsCompanion(
        glyphRevision: Value(project.glyphRevision + 1),
        baseRevision: Value(project.baseRevision + 1),
        memoUnlockedAt: Value(unlockedAt),
        updatedAt: Value(t),
      ),
    );
    await _deleteDraft(projectId, DraftKind.base, roleKey);
  });

  // ---- 커스텀 글리프 ----

  Future<CustomState?> customState(String projectId, int cp) async {
    final row = await _customRow(projectId, cp);
    return row == null ? null : _state(row);
  }

  Future<Map<int, CustomState>> customStates(String projectId) async {
    final rows = await (db.select(
      db.customGlyphs,
    )..where((c) => c.projectId.equals(projectId))).get();
    return {for (final r in rows) r.codePoint: _state(r)};
  }

  Future<List<CustomRevisionRow>> revisions(String projectId, int cp) =>
      (db.select(db.customRevisions)
            ..where(
              (r) => r.projectId.equals(projectId) & r.codePoint.equals(cp),
            )
            ..orderBy([
              (r) => OrderingTerm.asc(r.createdAt),
              (r) => OrderingTerm.asc(r.id),
            ]))
          .get();

  Future<GlyphOutline> revisionOutline(int revisionId) async {
    final row = await (db.select(
      db.customRevisions,
    )..where((r) => r.id.equals(revisionId))).getSingle();
    return decodeHwo1(row.outline);
  }

  /// 커스텀 글리프 저장: 새 수정본 추가 → 현재 수정본으로 지정, 선택 = custom.
  Future<SelectionChange> saveCustom(
    String projectId,
    int cp,
    List<InkStroke> strokes,
    GlyphOutline outline,
    PenStyle pen,
  ) => db.transaction(() async {
    final before = await customState(projectId, cp);
    final id = await db
        .into(db.customRevisions)
        .insert(
          CustomRevisionsCompanion.insert(
            projectId: projectId,
            codePoint: cp,
            strokes: encodeHws1(strokes),
            outline: encodeHwo1(outline),
            pen: jsonEncode(pen.toJson()),
            createdAt: now(),
          ),
        );
    final after = CustomState(GlyphSelection.custom, id);
    await _writeState(projectId, cp, after);
    await _bumpGlyphRevision(projectId);
    await _deleteDraft(projectId, DraftKind.custom, '$cp');
    return SelectionChange(projectId, cp, before, after);
  });

  /// 자동 생성으로 되돌리기. 커스텀이 아니면 null.
  Future<SelectionChange?> revertToGenerated(String projectId, int cp) =>
      _changeSelection(
        projectId,
        cp,
        (s) => s.selection == GlyphSelection.custom
            ? CustomState(GlyphSelection.generated, s.revisionId)
            : null,
      );

  /// 수정 이력이 있는 자동 생성 음절을 커스텀으로 다시 선택.
  Future<SelectionChange?> reselectCustom(String projectId, int cp) =>
      _changeSelection(
        projectId,
        cp,
        (s) => s.selection == GlyphSelection.generated
            ? CustomState(GlyphSelection.custom, s.revisionId)
            : null,
      );

  /// 수정 이력에서 현재 수정본 지정. 선택은 custom이 된다.
  Future<SelectionChange?> setCurrentRevision(
    String projectId,
    int cp,
    int revisionId,
  ) => _changeSelection(
    projectId,
    cp,
    (s) => s == CustomState(GlyphSelection.custom, revisionId)
        ? null
        : CustomState(GlyphSelection.custom, revisionId),
  );

  /// 실행 취소: 비교 후 교체 (Spec §9.1). 상태가 [SelectionChange.after]와 다르면 false.
  Future<bool> undo(SelectionChange change) => db.transaction(() async {
    final before = change.before;
    final target =
        before ??
        CustomState(GlyphSelection.generated, change.after.revisionId);
    final count = await db.customUpdate(
      'UPDATE custom_glyphs SET selection = ?, current_revision_id = ? '
      'WHERE project_id = ? AND code_point = ? '
      'AND selection = ? AND current_revision_id = ?',
      variables: [
        Variable.withString(target.selection.name),
        Variable.withInt(target.revisionId),
        Variable.withString(change.projectId),
        Variable.withInt(change.codePoint),
        Variable.withString(change.after.selection.name),
        Variable.withInt(change.after.revisionId),
      ],
      updates: {db.customGlyphs},
      updateKind: UpdateKind.update,
    );
    if (count == 0) return false;
    await _bumpGlyphRevision(change.projectId);
    return true;
  });

  /// 커스텀 글리프 삭제: 수정 이력 전체 삭제(POL-01의 허용된 경로).
  Future<void> deleteCustom(String projectId, int cp) =>
      db.withRevisionDeleteAllowed(() async {
        await (db.delete(db.customGlyphs)..where(
              (c) => c.projectId.equals(projectId) & c.codePoint.equals(cp),
            ))
            .go();
        await (db.delete(db.customRevisions)..where(
              (r) => r.projectId.equals(projectId) & r.codePoint.equals(cp),
            ))
            .go();
        await _bumpGlyphRevision(projectId);
      });

  // ---- 초안 ----

  /// 화면에 보이는 획 전체로 초안을 덮어쓴다. 획이 0개면 초안을 지운다(Spec §4.4).
  Future<void> saveDraft(
    String projectId,
    DraftKind kind,
    String key,
    List<InkStroke> strokes,
  ) async {
    if (strokes.isEmpty) return _deleteDraft(projectId, kind, key);
    await db
        .into(db.drafts)
        .insertOnConflictUpdate(
          DraftsCompanion.insert(
            projectId: projectId,
            kind: kind.name,
            key: key,
            strokes: encodeHws1(strokes),
            updatedAt: now(),
          ),
        );
  }

  Future<List<InkStroke>?> loadDraft(
    String projectId,
    DraftKind kind,
    String key,
  ) async {
    final row =
        await (db.select(db.drafts)..where(
              (d) =>
                  d.projectId.equals(projectId) &
                  d.kind.equals(kind.name) &
                  d.key.equals(key),
            ))
            .getSingleOrNull();
    return row == null ? null : decodeHws1(row.strokes);
  }

  Future<void> discardDraft(String projectId, DraftKind kind, String key) =>
      _deleteDraft(projectId, kind, key);

  // ---- 내부 ----

  Future<SelectionChange?> _changeSelection(
    String projectId,
    int cp,
    CustomState? Function(CustomState current) next,
  ) => db.transaction(() async {
    final before = await customState(projectId, cp);
    if (before == null) return null;
    final after = next(before);
    if (after == null) return null;
    await _writeState(projectId, cp, after);
    await _bumpGlyphRevision(projectId);
    return SelectionChange(projectId, cp, before, after);
  });

  Future<CustomGlyphRow?> _customRow(String projectId, int cp) =>
      (db.select(db.customGlyphs)..where(
            (c) => c.projectId.equals(projectId) & c.codePoint.equals(cp),
          ))
          .getSingleOrNull();

  CustomState _state(CustomGlyphRow r) => CustomState(
    GlyphSelection.values.byName(r.selection),
    r.currentRevisionId,
  );

  Future<void> _writeState(String projectId, int cp, CustomState s) => db
      .into(db.customGlyphs)
      .insertOnConflictUpdate(
        CustomGlyphsCompanion.insert(
          projectId: projectId,
          codePoint: cp,
          selection: s.selection.name,
          currentRevisionId: s.revisionId,
        ),
      );

  Future<void> _bumpGlyphRevision(String projectId) => db.customUpdate(
    'UPDATE projects SET glyph_revision = glyph_revision + 1, updated_at = ? WHERE id = ?',
    variables: [Variable.withInt(now()), Variable.withString(projectId)],
    updates: {db.projects},
    updateKind: UpdateKind.update,
  );

  Future<void> _deleteDraft(String projectId, DraftKind kind, String key) =>
      (db.delete(db.drafts)..where(
            (d) =>
                d.projectId.equals(projectId) &
                d.kind.equals(kind.name) &
                d.key.equals(key),
          ))
          .go();
}
