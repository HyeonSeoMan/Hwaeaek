/// Drift 저장소 (Spec §4). 스키마는 `schema.drift`.
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

@DriftDatabase(include: {'schema.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// 앱 문서 폴더의 `hwaeaek.sqlite`.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'hwaeaek'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'INSERT INTO revision_guard (id, allow_revision_delete) VALUES (1, 0)',
      );
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  /// 수정 이력 삭제가 허용된 두 경로(커스텀 글리프 삭제, 프로젝트 삭제)만 쓴다.
  /// 가드를 켜고 끄는 것까지 한 트랜잭션이다.
  Future<T> withRevisionDeleteAllowed<T>(Future<T> Function() body) =>
      transaction(() async {
        await customUpdate(
          'UPDATE revision_guard SET allow_revision_delete = 1 WHERE id = 1',
          updates: {revisionGuard},
        );
        final result = await body();
        await customUpdate(
          'UPDATE revision_guard SET allow_revision_delete = 0 WHERE id = 1',
          updates: {revisionGuard},
        );
        return result;
      });
}
