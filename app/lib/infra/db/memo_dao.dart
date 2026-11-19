/// 메모와 앱 설정 쓰기 (Spec §4.3, §9.2).
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/hangul/normalize.dart';
import 'database.dart';
import 'project_dao.dart';

/// 메모 하나의 글자 수 상한 (Spec §3.2).
const maxMemoLength = 100000;

class MemoDao {
  MemoDao(this.db, {Clock? clock}) : now = clock ?? systemClock;

  final AppDatabase db;
  final Clock now;

  Stream<List<MemoRow>> watch(String projectId) =>
      (db.select(db.memos)
            ..where((m) => m.projectId.equals(projectId))
            ..orderBy([(m) => OrderingTerm.desc(m.updatedAt)]))
          .watch();

  Future<MemoRow> get(String id) =>
      (db.select(db.memos)..where((m) => m.id.equals(id))).getSingle();

  Future<String> create(String projectId) async {
    final id = const Uuid().v4();
    final t = now();
    await db
        .into(db.memos)
        .insert(
          MemosCompanion.insert(
            id: id,
            projectId: projectId,
            text$: '',
            createdAt: t,
            updatedAt: t,
          ),
        );
    return id;
  }

  /// 저장 직전에 한글 정규화를 한 번 더 적용한다(Spec §8.3). 프로젝트의
  /// `updated_at`은 바꾸지 않는다.
  Future<void> updateText(String id, String text) {
    if (text.length > maxMemoLength) {
      throw ArgumentError.value(text.length, 'text.length');
    }
    return (db.update(db.memos)..where((m) => m.id.equals(id))).write(
      MemosCompanion(
        text$: Value(normalizeHangul(text).text),
        updatedAt: Value(now()),
      ),
    );
  }

  /// 즉시 삭제하고 지운 행을 돌려준다. 실행 취소는 [restore].
  Future<MemoRow> delete(String id) => db.transaction(() async {
    final row = await get(id);
    await (db.delete(db.memos)..where((m) => m.id.equals(id))).go();
    return row;
  });

  Future<void> restore(MemoRow row) => db.into(db.memos).insert(row);
}

class SettingsDao {
  SettingsDao(this.db);

  final AppDatabase db;

  static const drawWithFinger = 'draw_with_finger';

  Future<bool> getBool(String key, {bool fallback = false}) async {
    final row = await (db.select(
      db.appSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row == null ? fallback : row.value == 'true';
  }

  Future<void> setBool(String key, bool value) => db
      .into(db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: key, value: '$value'),
      );
}
