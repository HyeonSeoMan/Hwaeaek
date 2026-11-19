/// 앱 수준 provider (Spec §9.3). Riverpod 3, 코드 생성 없음.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infra/db/database.dart';
import '../infra/db/glyph_dao.dart';
import '../infra/db/memo_dao.dart';
import '../infra/db/project_dao.dart';
import 'pending_writes.dart';

/// 테스트는 메모리 DB로 덮어쓴다.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final pendingWritesProvider = Provider<PendingWrites>((ref) {
  final writes = PendingWrites();
  ref.onDispose(writes.dispose);
  return writes;
});

final projectDaoProvider = Provider(
  (ref) => ProjectDao(ref.watch(databaseProvider)),
);
final glyphDaoProvider = Provider(
  (ref) => GlyphDao(ref.watch(databaseProvider)),
);
final memoDaoProvider = Provider((ref) => MemoDao(ref.watch(databaseProvider)));
final settingsDaoProvider = Provider(
  (ref) => SettingsDao(ref.watch(databaseProvider)),
);
