/// 프로젝트·메모 목록 provider (Spec §9.3).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infra/db/database.dart';
import 'pending_writes.dart';
import 'providers.dart';

final projectListProvider = StreamProvider.autoDispose<List<ProjectRow>>(
  (ref) => ref.watch(projectDaoProvider).watchAll(),
);

final projectProvider = StreamProvider.autoDispose.family<ProjectRow, String>((
  ref,
  id,
) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.projects)..where((p) => p.id.equals(id))).watchSingle();
});

final memoListProvider = StreamProvider.autoDispose
    .family<List<MemoRow>, String>(
      (ref, projectId) => ref.watch(memoDaoProvider).watch(projectId),
    );

final writeBannerProvider = StreamProvider<WriteBanner>((ref) async* {
  final writes = ref.watch(pendingWritesProvider);
  yield writes.banner;
  yield* writes.bannerChanges;
});
