/// 음절 다시 그리기 흐름과 수정 이력 시트 (PRD FR-05, Spec §8.4, §9.1, §10).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/glyph/hwo1.dart';
import '../infra/db/database.dart';
import '../infra/db/glyph_dao.dart';
import '../state/glyph_actions.dart';
import '../state/providers.dart';
import '../state/snapshot.dart';
import 'glyph_editor_screen.dart';
import 'glyph_painter.dart';

/// 음절 [cp]의 커스텀 글리프 편집 화면을 연다. 저장하면 true.
Future<bool> redrawSyllable(
  BuildContext context,
  WidgetRef ref,
  String projectId,
  int cp,
) async {
  final ch = String.fromCharCode(cp);
  final renderer = ref.read(glyphRendererProvider(projectId));
  final saved = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => GlyphEditorScreen(
        GlyphEditorArgs(
          projectId: projectId,
          title: '‘$ch’ 다시 그리기',
          draftKind: DraftKind.custom,
          draftKey: '$cp',
          reference: renderer?.outline(cp),
          onSave: (strokes) =>
              ref.read(glyphActionsProvider(projectId)).saveCustom(cp, strokes),
          trailing: renderer?.snapshot.customs.containsKey(cp) ?? false
              ? Builder(
                  builder: (context) => IconButton(
                    tooltip: '수정 이력',
                    icon: const Icon(Icons.history),
                    onPressed: () =>
                        showRevisionHistory(context, ref, projectId, cp),
                  ),
                )
              : null,
        ),
      ),
    ),
  );
  if ((saved ?? false) && context.mounted) {
    showUndoSnackBar(context, ref, '‘$ch’를 내 글씨로 바꿨습니다');
  }
  return saved ?? false;
}

/// 실행 취소 스낵바(5초). 사라지면 실행 취소 슬롯을 비운다(Spec §9.1).
void showUndoSnackBar(BuildContext context, WidgetRef ref, String message) {
  final undo = ref.read(undoProvider.notifier);
  final controller = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  final bar = controller.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: '실행 취소',
        onPressed: () async {
          final result = await undo.undo();
          if (result == UndoResult.notPossible && context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('되돌릴 수 없습니다')));
          }
        },
      ),
    ),
  );
  unawaited(
    bar.closed.then((reason) {
      if (reason != SnackBarClosedReason.action) undo.clear();
    }),
  );
}

/// 수정 이력 시트: 최신순 썸네일, 현재 수정본 표시, 눌러서 지정, 커스텀 삭제.
Future<void> showRevisionHistory(
  BuildContext context,
  WidgetRef ref,
  String projectId,
  int cp,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (sheetContext) => _RevisionHistory(projectId: projectId, cp: cp),
);

class _RevisionHistory extends ConsumerWidget {
  const _RevisionHistory({required this.projectId, required this.cp});

  final String projectId;
  final int cp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(snapshotProvider(projectId)).value;
    final current = snapshot?.customs[cp];
    return FutureBuilder<List<CustomRevisionRow>>(
      // 스냅샷이 바뀔 때마다 다시 읽는다.
      key: ValueKey(snapshot?.revision),
      future: ref.read(glyphDaoProvider).revisions(projectId, cp),
      builder: (context, data) {
        final revisions = (data.data ?? const <CustomRevisionRow>[]).reversed
            .toList();
        final actions = ref.read(glyphActionsProvider(projectId));
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '‘${String.fromCharCode(cp)}’ 수정 이력',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: revisions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final r = revisions[i];
                      final isCurrent =
                          current?.selection == GlyphSelection.custom &&
                          current?.revisionId == r.id;
                      return InkWell(
                        onTap: isCurrent
                            ? null
                            : () async {
                                await actions.setCurrentRevision(cp, r.id);
                                if (context.mounted) {
                                  showUndoSnackBar(
                                    context,
                                    ref,
                                    '수정본 ${revisions.length - i}을 쓰도록 바꿨습니다',
                                  );
                                }
                              },
                        child: Card.outlined(
                          shape: isCurrent
                              ? RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                )
                              : null,
                          child: SizedBox.square(
                            dimension: 104,
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: CustomPaint(
                                    size: Size.infinite,
                                    painter: GlyphPainter(
                                      decodeHwo1(r.outline),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 6,
                                  top: 4,
                                  child: Text(
                                    isCurrent
                                        ? '현재'
                                        : '${revisions.length - i}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                if (current?.selection == GlyphSelection.custom)
                  OutlinedButton(
                    onPressed: () async {
                      await actions.revertToGenerated(cp);
                      if (context.mounted) {
                        showUndoSnackBar(
                          context,
                          ref,
                          '자동 생성으로 되돌렸습니다 (내 글씨는 보존됨)',
                        );
                      }
                    },
                    child: const Text('자동 생성으로 되돌리기'),
                  ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('커스텀 글리프를 삭제할까요?'),
                        content: Text(
                          '수정본 ${revisions.length}개가 모두 지워지고 되돌릴 수 없습니다.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                    );
                    if (ok ?? false) {
                      await actions.deleteCustom(cp);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('커스텀 글리프 삭제'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
