import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:hwaeaek/dev/stroke_fixture.dart';
import 'package:hwaeaek/domain/compose/composer.dart';
import 'package:hwaeaek/domain/ink/ink.dart';
import 'package:hwaeaek/infra/db/database.dart';
import 'package:hwaeaek/infra/db/glyph_dao.dart';
import 'package:hwaeaek/infra/db/memo_dao.dart';
import 'package:hwaeaek/infra/db/project_dao.dart';

/// 테스트용 DB와 DAO 묶음. 시각은 1씩 증가하는 가짜 시계.
class TestDb {
  TestDb(this.db) {
    var t = 1000;
    int clock() => t++;
    projects = ProjectDao(db, clock: clock);
    glyphs = GlyphDao(db, clock: clock);
    memos = MemoDao(db, clock: clock);
  }

  factory TestDb.memory() => TestDb(AppDatabase(NativeDatabase.memory()));

  factory TestDb.file(File file) => TestDb(AppDatabase(NativeDatabase(file)));

  final AppDatabase db;
  late final ProjectDao projects;
  late final GlyphDao glyphs;
  late final MemoDao memos;

  Future<void> close() => db.close();

  Future<int> count(String table) async {
    final row = await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
    return row.read<int>('c');
  }

  /// 필수 기본 글리프 35자를 모두 저장한 프로젝트.
  Future<String> projectWithBaseGlyphs() async {
    final id = await projects.create('테스트');
    for (final MapEntry(:key, :value) in strokeFixture().entries) {
      await glyphs.saveBaseGlyph(id, key, value);
    }
    return id;
  }

  /// 음절 [cp]의 커스텀 수정본 하나를 저장한다(획은 픽스처 ㅇ).
  Future<SelectionChange> saveCustom(String projectId, int cp) {
    final strokes = strokeFixture()['ㅇ']!;
    return glyphs.saveCustom(
      projectId,
      cp,
      strokes,
      strokesToOutline(strokes),
      PenStyle.base,
    );
  }
}

final kang = '강'.runes.first;
final gak = '각'.runes.first;

Map<String, List<InkStroke>> get fixture => strokeFixture();

HangulComposer composerFor(Map<String, List<InkStroke>> base) => HangulComposer(base);

Future<void> exec(AppDatabase db, String sql) => db.customStatement(sql);

extension Rows on AppDatabase {
  Future<List<QueryRow>> rows(String sql) => customSelect(sql).get();
}
