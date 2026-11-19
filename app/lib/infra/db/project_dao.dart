/// 프로젝트 쓰기·읽기 (Spec §4.3).
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/compose/composer.dart';
import '../../domain/font/naming.dart';
import '../../domain/hangul/base_set.dart';
import 'database.dart';

typedef Clock = int Function();

int systemClock() => DateTime.now().millisecondsSinceEpoch;

class ProjectDao {
  ProjectDao(this.db, {Clock? clock}) : now = clock ?? systemClock;

  final AppDatabase db;
  final Clock now;

  Stream<List<ProjectRow>> watchAll() => (db.select(
    db.projects,
  )..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])).watch();

  Future<ProjectRow> get(String id) =>
      (db.select(db.projects)..where((p) => p.id.equals(id))).getSingle();

  /// 새 프로젝트. 폰트 이름 기본값 (Spec §3.2).
  Future<String> create(String name) async {
    final id = const Uuid().v4();
    final t = now();
    await db
        .into(db.projects)
        .insert(
          ProjectsCompanion.insert(
            id: id,
            name: name,
            createdAt: t,
            updatedAt: t,
            baseSetVersion: latestBaseSetVersion,
            ruleVersion: HangulComposer.ruleVersion,
            fontFamilyName: name,
            fontAsciiName: 'Hwaeaek-${id.substring(0, 8)}',
          ),
        );
    return id;
  }

  /// 프로젝트 이름만 바꾼다. 폰트 패밀리 이름은 따라 바뀌지 않는다.
  Future<void> rename(String id, String name) =>
      (db.update(db.projects)..where((p) => p.id.equals(id))).write(
        ProjectsCompanion(name: Value(name), updatedAt: Value(now())),
      );

  /// 프로젝트 삭제. 수정 이력이 CASCADE로 지워지는 허용된 경로다(POL-01).
  Future<void> delete(String id) => db.withRevisionDeleteAllowed(
    () => (db.delete(db.projects)..where((p) => p.id.equals(id))).go(),
  );

  /// 프로젝트를 열 때: 앱이 아는 세트 버전이 더 높으면 올린다(Spec §3.2, TS-20).
  Future<void> open(String id) =>
      (db.update(db.projects)..where(
            (p) =>
                p.id.equals(id) &
                p.baseSetVersion.isSmallerThanValue(latestBaseSetVersion),
          ))
          .write(
            const ProjectsCompanion(
              baseSetVersion: Value(latestBaseSetVersion),
            ),
          );

  /// 폰트 메타데이터 변경. ASCII 이름이 바뀌면 버전을 0으로 되돌린다(Spec §7.4).
  Future<void> updateFontMetadata(
    String id, {
    required String familyName,
    required String asciiFamilyName,
    required String license,
  }) async {
    final error = asciiFamilyNameError(asciiFamilyName);
    if (error != null) {
      throw ArgumentError.value(asciiFamilyName, 'asciiFamilyName', error);
    }
    await db.transaction(() async {
      final current = await get(id);
      await (db.update(db.projects)..where((p) => p.id.equals(id))).write(
        ProjectsCompanion(
          fontFamilyName: Value(familyName),
          fontAsciiName: Value(asciiFamilyName),
          fontLicense: Value(license),
          fontVersionMinor: current.fontAsciiName == asciiFamilyName
              ? const Value.absent()
              : const Value(0),
          updatedAt: Value(now()),
        ),
      );
    });
  }

  /// 내보내기 커밋 (Spec §7.2 9단계).
  Future<void> commitFontVersion(String id, int versionMinor) =>
      (db.update(db.projects)..where((p) => p.id.equals(id))).write(
        ProjectsCompanion(fontVersionMinor: Value(versionMinor)),
      );
}
