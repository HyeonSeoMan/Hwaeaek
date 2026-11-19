/// 스냅샷 provider와 조합 엔진 provider (Spec §3.3, §6.5, §9.3).
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/compose/composer.dart';
import '../domain/glyph/glyph.dart';
import '../domain/glyph/hwo1.dart';
import '../domain/project/snapshot.dart';
import '../infra/db/database.dart';
import '../infra/db/glyph_dao.dart';
import 'providers.dart';

/// 읽기 트랜잭션 하나로 스냅샷을 만든다.
Future<GlyphSnapshot> loadSnapshot(AppDatabase db, String projectId) =>
    db.transaction(() async {
      final p = await (db.select(
        db.projects,
      )..where((p) => p.id.equals(projectId))).getSingle();
      final base = await GlyphDao(db).baseGlyphs(projectId);
      final rows = await db
          .customSelect(
            'SELECT g.code_point AS cp, g.selection AS sel, g.current_revision_id AS rev, '
            'r.outline AS outline FROM custom_glyphs g '
            'JOIN custom_revisions r ON r.id = g.current_revision_id '
            'WHERE g.project_id = ?',
            variables: [Variable.withString(projectId)],
            readsFrom: {db.customGlyphs, db.customRevisions},
          )
          .get();
      return GlyphSnapshot(
        projectId: projectId,
        revision: p.glyphRevision,
        baseRevision: p.baseRevision,
        baseSetVersion: p.baseSetVersion,
        memoUnlocked: p.memoUnlockedAt != null,
        baseStrokes: base,
        customs: {
          for (final r in rows)
            r.read<int>('cp'): CustomEntry(
              GlyphSelection.values.byName(r.read<String>('sel')),
              r.read<int>('rev'),
              decodeHwo1(r.read<Uint8List>('outline')),
            ),
        },
        metadata: FontMetadata(
          familyName: p.fontFamilyName,
          asciiFamilyName: p.fontAsciiName,
          styleName: p.fontStyleName,
          versionMinor: p.fontVersionMinor,
          license: p.fontLicense,
        ),
      );
    });

/// 프로젝트 행을 구독하되 글리프 revision이나 폰트 메타데이터가 바뀔 때만
/// 스냅샷을 다시 만든다. 메모 쓰기는 프로젝트 행을 바꾸지 않는다.
final snapshotProvider = StreamProvider.autoDispose
    .family<GlyphSnapshot, String>((ref, projectId) {
      final db = ref.watch(databaseProvider);
      return (db.select(db.projects)..where((p) => p.id.equals(projectId)))
          .watchSingle()
          .map(
            (p) => (
              p.glyphRevision,
              p.fontFamilyName,
              p.fontAsciiName,
              p.fontStyleName,
              p.fontVersionMinor,
              p.fontLicense,
              p.baseSetVersion,
            ),
          )
          .distinct()
          .asyncMap((_) => loadSnapshot(db, projectId));
    });

/// 스냅샷 + 캐시된 조합 엔진. 앱 안 표시와 내보내기가 같은 [outline]을 쓴다.
class GlyphRenderer {
  GlyphRenderer(this.snapshot, this.composer);

  final GlyphSnapshot snapshot;
  final CachedComposer composer;

  /// 유효 글리프. null이면 조합 오류.
  GlyphOutline? outline(int cp) =>
      effectiveGlyph(snapshot, composer.compose, cp);
}

/// 조합 엔진은 `baseRevision`이 바뀔 때만 새로 만든다(Spec §6.5). 커스텀·선택
/// 변경은 캐시를 그대로 쓴다.
class GlyphRendererNotifier extends Notifier<GlyphRenderer?> {
  GlyphRendererNotifier(this.projectId);

  final String projectId;

  @override
  GlyphRenderer? build() {
    final snapshot = ref.watch(snapshotProvider(projectId)).value;
    if (snapshot == null) return stateOrNull;
    final previous = stateOrNull;
    final composer =
        previous != null &&
            previous.snapshot.baseRevision == snapshot.baseRevision
        ? previous.composer
        : CachedComposer(HangulComposer(snapshot.baseStrokes));
    return GlyphRenderer(snapshot, composer);
  }
}

final glyphRendererProvider = NotifierProvider.autoDispose
    .family<GlyphRendererNotifier, GlyphRenderer?, String>(
      GlyphRendererNotifier.new,
    );
