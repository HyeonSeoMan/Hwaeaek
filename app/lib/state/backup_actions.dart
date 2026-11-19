/// 백업 만들기·가져오기 동작 (PRD FR-09, Spec §11.2).
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../app_info.dart';
import '../infra/backup/backup.dart';
import '../infra/platform/files.dart';
import 'export_job.dart';
import 'providers.dart';

final backupTempDirProvider = FutureProvider<Directory>(
  (ref) => getTemporaryDirectory(),
);

/// 테스트는 가짜 선택기로 바꾼다.
final backupPickerProvider = Provider<Future<File?> Function()>(
  (ref) => pickBackupFile,
);

class BackupActions {
  BackupActions(this.ref);

  final Ref ref;

  /// 백업을 만들어 저장한다. 실패하면 사용자에게 보일 메시지를 던진다.
  Future<File> createAndSave(String projectId) async {
    if (ref.read(pendingWritesProvider).hasPendingGlyphWrites) {
      throw const BackupMessage('저장되지 않은 변경이 있습니다. 저장된 뒤 다시 시도해 주세요.');
    }
    final dir = await ref.read(backupTempDirProvider.future);
    final File file;
    try {
      file = await writeBackup(
        ref.read(databaseProvider),
        projectId,
        dir,
        appVersion: appVersion,
      );
    } on BackupError {
      throw const BackupMessage('백업을 만들 수 없습니다.');
    }
    await ref
        .read(fileDeliveryProvider)
        .save(file, fileName: file.uri.pathSegments.last);
    return file;
  }

  /// 백업 파일을 골라 새 프로젝트로 가져온다. 취소하면 null.
  Future<String?> pickAndImport() async {
    final file = await ref.read(backupPickerProvider)();
    if (file == null) return null;
    try {
      return await importBackup(ref.read(databaseProvider), file);
    } on BackupError catch (e) {
      throw BackupMessage(e.code.message);
    }
  }
}

class BackupMessage implements Exception {
  const BackupMessage(this.message);

  final String message;

  @override
  String toString() => message;
}

final backupActionsProvider = Provider(BackupActions.new);
