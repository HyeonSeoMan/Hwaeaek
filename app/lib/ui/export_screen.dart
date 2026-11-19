/// 내보내기 진행 화면과 결과 시트 (PRD FR-08, Spec §7.2).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/font/export.dart';
import '../state/export_job.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final _shareButton = GlobalKey();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(exportJobProvider(widget.projectId).notifier).start(),
    );
  }

  /// iPad 공유 팝오버 위치.
  Rect? _origin() {
    final box = _shareButton.currentContext?.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exportJobProvider(widget.projectId));
    final job = ref.read(exportJobProvider(widget.projectId).notifier);
    final busy = state is ExportBuilding || state is ExportDelivering;
    return PopScope(
      // 계산·저장 중에는 나갈 수 없다(편집도 막힌다).
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TTF 내보내기'),
          automaticallyImplyLeading: !busy,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (state) {
            ExportIdle() => const Center(child: CircularProgressIndicator()),
            ExportBuilding(:final progress, :final done) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('글자 11,223개를 만들고 있습니다'),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Text(
                  '$done / $exportTotal',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            ExportReady() || ExportDelivering() => _Result(
              ready: switch (state) {
                ExportReady() => state,
                ExportDelivering(:final ready) => ready,
                _ => throw StateError('unreachable'),
              },
              busy: state is ExportDelivering,
              shareKey: _shareButton,
              onSave: () => job.deliver(ExportTarget.save),
              onShare: () => job.deliver(ExportTarget.share, origin: _origin()),
              onCancel: () => Navigator.pop(context),
            ),
            ExportDone(:final file, :final versionMinor) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.check_circle_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  '폰트를 만들었습니다 (버전 1.${versionMinor.toString().padLeft(3, '0')})',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(file.uri.pathSegments.last, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => job.redeliver(ExportTarget.save),
                  child: const Text('다시 저장'),
                ),
                OutlinedButton(
                  key: _shareButton,
                  onPressed: () =>
                      job.redeliver(ExportTarget.share, origin: _origin()),
                  child: const Text('다시 공유'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('완료'),
                ),
              ],
            ),
            ExportFailed(:final message) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => unawaited(job.start()),
                  child: const Text('다시 시도'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

/// 결과 시트: 제외 음절 수와 목록을 저장·공유 전에 보여 준다(FR-08).
class _Result extends StatelessWidget {
  const _Result({
    required this.ready,
    required this.busy,
    required this.shareKey,
    required this.onSave,
    required this.onShare,
    required this.onCancel,
  });

  final ExportReady ready;
  final bool busy;
  final Key shareKey;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final excluded = ready.build.excluded;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(ready.fileName, style: text.titleMedium),
        const SizedBox(height: 4),
        Text(
          '${(ready.build.bytes.length / 1048576).toStringAsFixed(1)}MB · 글자 ${ready.build.validCount}개',
        ),
        const SizedBox(height: 16),
        if (excluded.isEmpty)
          const Text('모든 글자가 들어갔습니다.')
        else ...[
          Text('${excluded.length}자는 만들 수 없어 빠집니다', style: text.titleSmall),
          Text(
            '외부 프로그램에서는 다른 폰트로 보입니다. 기본 글리프를 보강하거나 직접 그리면 들어갑니다.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                // 빈도 순 정렬은 단계 7(Spec §14). 지금은 Unicode 순.
                excluded.map(String.fromCharCode).join(' '),
                style: const TextStyle(fontSize: 18, height: 1.6),
              ),
            ),
          ),
        ],
        if (excluded.isEmpty) const Spacer(),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: busy ? null : onSave,
          icon: const Icon(Icons.save_alt),
          label: const Text('저장'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: shareKey,
          onPressed: busy ? null : onShare,
          icon: const Icon(Icons.ios_share),
          label: const Text('공유'),
        ),
        TextButton(onPressed: busy ? null : onCancel, child: const Text('취소')),
      ],
    );
  }
}
