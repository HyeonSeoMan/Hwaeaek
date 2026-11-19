/// TTF 내보내기 작업 (PRD FR-08, Spec §7.2, §7.4).
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/painting.dart' show Rect;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/font/export.dart';
import '../domain/hangul/base_set.dart';
import '../domain/project/snapshot.dart';
import '../infra/platform/files.dart';
import 'providers.dart';
import 'snapshot.dart';

final exportsRootProvider = FutureProvider<Directory>(
  (ref) => defaultExportsRoot(),
);
final fileDeliveryProvider = Provider<FileDelivery>(
  (ref) => const PlatformFileDelivery(),
);

sealed class ExportState {
  const ExportState();
}

class ExportIdle extends ExportState {
  const ExportIdle();
}

class ExportBuilding extends ExportState {
  const ExportBuilding(this.done);

  final int done;
  double get progress => done / exportTotal;
}

/// 결과 시트(6단계): 제외 목록을 보여 주고 저장·공유를 기다린다.
class ExportReady extends ExportState {
  const ExportReady(this.build, this.fileName);

  final ExportBuild build;
  final String fileName;
}

class ExportDelivering extends ExportState {
  const ExportDelivering(this.ready);

  final ExportReady ready;
}

class ExportDone extends ExportState {
  const ExportDone(this.file, this.versionMinor);

  final File file;
  final int versionMinor;
}

class ExportFailed extends ExportState {
  const ExportFailed(this.message);

  final String message;
}

enum ExportTarget { save, share }

const _keepFiles = 3;

class ExportJob extends Notifier<ExportState> {
  ExportJob(this.projectId);

  final String projectId;

  @override
  ExportState build() => const ExportIdle();

  Future<Directory> _dir() async {
    final root = await ref.read(exportsRootProvider.future);
    return Directory('${root.path}/$projectId')..createSync(recursive: true);
  }

  /// 1~5단계: 확인 → 스냅샷 → isolate 계산·빌드 → 결과 시트.
  Future<void> start() async {
    if (state is ExportBuilding || state is ExportDelivering) return;
    if (ref.read(pendingWritesProvider).hasPendingGlyphWrites) {
      state = const ExportFailed('저장되지 않은 변경이 있습니다. 저장된 뒤 다시 시도해 주세요.');
      return;
    }
    final snapshot = await loadSnapshot(ref.read(databaseProvider), projectId);
    if (!hasAllRequired(snapshot.baseStrokes.keys, snapshot.baseSetVersion)) {
      state = const ExportFailed('필수 기본 글리프를 모두 써야 내보낼 수 있습니다.');
      return;
    }
    final m = snapshot.metadata;
    if (m.versionMinor >= 999) {
      state = const ExportFailed(
        '폰트 버전이 최대입니다. 설정에서 영문 이름을 바꾸면 버전이 1.001부터 다시 시작합니다.',
      );
      return;
    }
    await _cleanParts();
    final n = m.versionMinor + 1;
    state = const ExportBuilding(0);
    try {
      final build = await _buildInIsolate(snapshot, n, DateTime.now().toUtc(), (
        done,
      ) {
        if (ref.mounted && state is ExportBuilding) {
          state = ExportBuilding(done);
        }
      });
      if (!ref.mounted) return;
      state = ExportReady(build, '${m.asciiFamilyName}-v$n.ttf');
    } catch (e) {
      if (ref.mounted) state = ExportFailed('폰트를 만들지 못했습니다: $e');
    }
  }

  /// 6단계에서 취소. 아무것도 쓰지 않는다.
  void cancel() => state = const ExportIdle();

  /// 7~10단계: .part 쓰기 → 디스크에서 다시 읽어 검증 → 버전 커밋 → 이름 바꾸기 → 전달.
  Future<void> deliver(ExportTarget target, {Rect? origin}) async {
    final ready = state;
    if (ready is! ExportReady) return;
    state = ExportDelivering(ready);
    final dir = await _dir();
    final file = File('${dir.path}/${ready.fileName}');
    final part = File('${file.path}.part');
    try {
      await part.writeAsBytes(ready.build.bytes, flush: true);
      verifyExport(await part.readAsBytes(), ready.build.validCount);
      await ref
          .read(projectDaoProvider)
          .commitFontVersion(projectId, ready.build.versionMinor);
    } catch (e) {
      if (part.existsSync()) await part.delete();
      if (ref.mounted) state = ExportFailed('폰트 파일을 저장하지 못했습니다: $e');
      return;
    }
    // 커밋 뒤에 실패하면 버전 번호 하나를 건너뛸 뿐 사용자 작업은 그대로다(POL-06).
    await part.rename(file.path);
    await _prune(dir);
    final delivery = ref.read(fileDeliveryProvider);
    try {
      switch (target) {
        case ExportTarget.save:
          await delivery.save(file, fileName: ready.fileName);
        case ExportTarget.share:
          await delivery.share(file, fileName: ready.fileName, origin: origin);
      }
    } catch (_) {
      // 파일은 이미 만들어졌다. 사용자는 다시 저장·공유할 수 있다.
    }
    if (ref.mounted) state = ExportDone(file, ready.build.versionMinor);
  }

  /// 완료 화면에서 같은 파일을 다시 저장·공유한다.
  Future<void> redeliver(ExportTarget target, {Rect? origin}) async {
    final done = state;
    if (done is! ExportDone) return;
    final delivery = ref.read(fileDeliveryProvider);
    final name = done.file.uri.pathSegments.last;
    switch (target) {
      case ExportTarget.save:
        await delivery.save(done.file, fileName: name);
      case ExportTarget.share:
        await delivery.share(done.file, fileName: name, origin: origin);
    }
  }

  /// 남은 .part 정리 (앱 시작·내보내기 시작 때).
  Future<void> _cleanParts() async {
    final dir = await _dir();
    for (final f in dir.listSync().whereType<File>()) {
      if (f.path.endsWith('.part')) await f.delete();
    }
  }

  /// 최근 [_keepFiles]개만 남긴다.
  Future<void> _prune(Directory dir) async {
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.ttf'))
            .toList()
          ..sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
          );
    for (final f in files.skip(_keepFiles)) {
      await f.delete();
    }
  }
}

final exportJobProvider = NotifierProvider.autoDispose
    .family<ExportJob, ExportState, String>(ExportJob.new);

/// 진행률을 보고하며 백그라운드 isolate에서 계산·빌드한다(Spec §7.2 4~5단계).
Future<ExportBuild> _buildInIsolate(
  GlyphSnapshot snapshot,
  int versionMinor,
  DateTime created,
  void Function(int done) onProgress,
) async {
  final port = ReceivePort();
  final errors = ReceivePort();
  await Isolate.spawn(_exportEntry, (
    port.sendPort,
    snapshot,
    versionMinor,
    created,
  ), onError: errors.sendPort);
  final result = Completer<ExportBuild>();
  errors.listen((e) {
    if (!result.isCompleted) result.completeError(StateError('$e'));
  });
  port.listen((msg) {
    if (msg is int) {
      onProgress(msg);
    } else if (msg is ExportBuild && !result.isCompleted) {
      result.complete(msg);
    }
  });
  try {
    return await result.future;
  } finally {
    port.close();
    errors.close();
  }
}

void _exportEntry((SendPort, GlyphSnapshot, int, DateTime) args) {
  final (send, snapshot, versionMinor, created) = args;
  send.send(
    buildExport(
      snapshot,
      versionMinor: versionMinor,
      created: created,
      onProgress: send.send,
    ),
  );
}
