/// 기본 글리프 목록과 작성 (PRD FR-03, Spec §10).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/hangul/base_set.dart';
import '../infra/db/glyph_dao.dart';
import '../state/glyph_actions.dart';
import '../state/snapshot.dart';
import 'glyph_editor_screen.dart';
import 'glyph_painter.dart';

class BaseGlyphScreen extends ConsumerWidget {
  const BaseGlyphScreen({super.key, required this.projectId});

  final String projectId;

  /// 자모 [jamo]의 편집 화면을 연다. 저장하면 true.
  Future<bool> _edit(BuildContext context, WidgetRef ref, String jamo) async {
    final renderer = ref.read(glyphRendererProvider(projectId));
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GlyphEditorScreen(
          GlyphEditorArgs(
            projectId: projectId,
            title: '기본 글리프 ‘$jamo’',
            draftKind: DraftKind.base,
            draftKey: jamo,
            guideJamo: jamo,
            initialStrokes: renderer?.snapshot.baseStrokes[jamo] ?? const [],
            onSave: (strokes) => ref
                .read(glyphActionsProvider(projectId))
                .saveBaseGlyph(jamo, strokes),
          ),
        ),
      ),
    );
    return saved ?? false;
  }

  /// 아직 쓰지 않은 필수 자모를 순서대로 이어서 쓴다(Spec §10 입력 순서).
  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    final renderer = ref.read(glyphRendererProvider(projectId));
    if (renderer == null) return;
    // 스냅샷 갱신은 비동기이므로 이번에 쓴 자모를 따로 기억한다.
    final written = renderer.snapshot.baseStrokes.keys.toSet();
    for (final next in requiredBaseGlyphs(renderer.snapshot.baseSetVersion)) {
      if (written.contains(next)) continue;
      if (!context.mounted || !await _edit(context, ref, next)) return;
      written.add(next);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final renderer = ref.watch(glyphRendererProvider(projectId));
    if (renderer == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final version = renderer.snapshot.baseSetVersion;
    final written = renderer.snapshot.baseStrokes.keys.toSet();
    final required = requiredBaseGlyphs(version);
    final done = required.where(written.contains).length;
    final colors = Theme.of(context).colorScheme;

    Widget cell(String jamo, {required bool isRequired}) {
      final has = written.contains(jamo);
      return InkWell(
        key: Key('base-$jamo'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => _edit(context, ref, jamo),
        child: Card.outlined(
          color: has ? null : colors.surfaceContainerLow,
          child: Stack(
            children: [
              Positioned(
                left: 8,
                top: 6,
                child: Text(
                  jamo,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              if (!has && isRequired)
                Positioned(
                  right: 8,
                  top: 6,
                  child: Text(
                    '작성 필요',
                    style: TextStyle(fontSize: 11, color: colors.error),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: GlyphPainter(
                    renderer.outline(jamo.runes.first),
                    // 보강 자모를 아직 안 썼으면 구성 자음 조합을 흐리게 보여 준다.
                    color: has
                        ? colors.onSurface
                        : colors.onSurface.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget grid(List<String> jamo, {required bool isRequired}) =>
        SliverGrid.extent(
          maxCrossAxisExtent: 110,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [for (final j in jamo) cell(j, isRequired: isRequired)],
        );

    return Scaffold(
      appBar: AppBar(title: const Text('기본 글리프')),
      floatingActionButton: done < required.length
          ? FloatingActionButton.extended(
              onPressed: () => _continue(context, ref),
              icon: const Icon(Icons.edit),
              label: const Text('이어서 쓰기'),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '필수 $done / ${required.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: done / required.length),
                  const SizedBox(height: 4),
                  Text(
                    done == required.length
                        ? '필수 글리프를 모두 썼습니다. 메모에서 내 글씨로 써 보세요.'
                        : '필수 글리프를 모두 쓰면 메모를 쓸 수 있습니다.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: grid(required, isRequired: true),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                '보강 (선택) — 쓰지 않으면 구성 자음으로 만듭니다',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            sliver: grid(supplementaryBaseGlyphs(version), isRequired: false),
          ),
        ],
      ),
    );
  }
}
