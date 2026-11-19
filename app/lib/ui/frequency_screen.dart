/// 빈도순 음절 목록 (PRD FR-06, Spec §10.1).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/project/snapshot.dart';
import '../state/frequency.dart';
import '../state/snapshot.dart';
import 'custom_glyph_flow.dart';
import 'glyph_painter.dart';

class FrequencyScreen extends ConsumerWidget {
  const FrequencyScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(frequencyOrderProvider).value;
    final renderer = ref.watch(glyphRendererProvider(projectId));
    if (order == null || renderer == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final colors = Theme.of(context).colorScheme;
    final ksx = order.source.startsWith('source=KS X 1001');
    return Scaffold(
      appBar: AppBar(title: const Text('자주 쓰는 글자')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                ksx
                    ? '자주 쓰는 완성형 2,350자부터 보여 줍니다. 어색한 글자를 눌러 다시 그리세요.'
                    : '자주 쓰는 순서로 보여 줍니다. 어색한 글자를 눌러 다시 그리세요.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            // 보이는 칸만 조합한다(Spec §10.1).
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 76,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: order.syllables.length,
              itemBuilder: (context, i) {
                final cp = order.syllables[i];
                final outline = renderer.outline(cp);
                final custom =
                    renderer.snapshot.customs[cp]?.selection ==
                    GlyphSelection.custom;
                return InkWell(
                  key: Key('freq-$cp'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => redrawSyllable(context, ref, projectId, cp),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: custom ? colors.primary : colors.outlineVariant,
                        width: custom ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: outline == null
                              // 조합 오류: 시스템 폰트 + 점선 대신 흐린 글자로 표시
                              ? Center(
                                  child: Text(
                                    String.fromCharCode(cp),
                                    style: TextStyle(
                                      fontSize: 28,
                                      color: colors.outline,
                                    ),
                                  ),
                                )
                              : CustomPaint(
                                  size: Size.infinite,
                                  painter: GlyphPainter(
                                    outline,
                                    color: colors.onSurface,
                                  ),
                                ),
                        ),
                        if (custom)
                          Positioned(
                            right: 4,
                            top: 2,
                            child: Text(
                              '내 글씨',
                              style: TextStyle(
                                fontSize: 9,
                                color: colors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
