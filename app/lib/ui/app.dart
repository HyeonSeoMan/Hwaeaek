/// 앱 루트와 저장 실패 배너 (Spec §4.3).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../state/pending_writes.dart';
import '../state/projects.dart';
import 'project_screens.dart';

class HwaeaekApp extends StatelessWidget {
  const HwaeaekApp({super.key, this.home = const ProjectListScreen()});

  final Widget home;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '회애액',
    theme: ThemeData(colorSchemeSeed: const Color(0xFF3B6E5A)),
    darkTheme: ThemeData(
      colorSchemeSeed: const Color(0xFF3B6E5A),
      brightness: Brightness.dark,
    ),
    builder: (context, child) => Column(
      children: [
        const _WriteBanner(),
        Expanded(child: child!),
      ],
    ),
    home: home,
  );
}

class _WriteBanner extends ConsumerWidget {
  const _WriteBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banner = ref.watch(writeBannerProvider).value ?? WriteBanner.none;
    if (banner == WriteBanner.none) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.sync_problem, color: colors.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  banner == WriteBanner.storageFull
                      ? '저장 공간이 부족합니다. 공간을 확보하거나 백업을 내보내 주세요.'
                      : '저장하지 못했습니다. 다시 시도하는 중…',
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
