import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/domain/hangul/base_set.dart';
import 'package:hwaeaek/infra/db/glyph_dao.dart';
import 'package:hwaeaek/state/pending_writes.dart' show sqliteResultCode;
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import '../../support/db.dart';

void main() {
  late TestDb t;
  late String p;

  setUp(() async {
    t = TestDb.memory();
    p = await t.projectWithBaseGlyphs();
  });
  tearDown(() => t.close());

  group('기본 글리프', () {
    test('필수 35자를 다 쓰면 memo_unlocked_at이 정해지고, 다시 비우지 않는다', () async {
      final fresh = await t.projects.create('새');
      for (final key in requiredBaseGlyphs(1).take(34)) {
        await t.glyphs.saveBaseGlyph(fresh, key, fixture[key]!);
      }
      expect((await t.projects.get(fresh)).memoUnlockedAt, isNull);
      await t.glyphs.saveBaseGlyph(fresh, 'ㅢ', fixture['ㅢ']!);
      final unlocked = (await t.projects.get(fresh)).memoUnlockedAt;
      expect(unlocked, isNotNull);
      await t.glyphs.saveBaseGlyph(fresh, 'ㄱ', fixture['ㄱ']!);
      expect((await t.projects.get(fresh)).memoUnlockedAt, unlocked);
    });

    test('기본 글리프 저장은 glyph_revision과 base_revision을 함께 올린다', () async {
      final before = await t.projects.get(p);
      await t.glyphs.saveBaseGlyph(p, 'ㄱ', fixture['ㄱ']!);
      final after = await t.projects.get(p);
      expect(after.glyphRevision, before.glyphRevision + 1);
      expect(after.baseRevision, before.baseRevision + 1);
    });
  });

  group('커스텀 글리프 (FR-05)', () {
    test('TS-04 되돌린 뒤에도 수정 이력은 보존되어 다시 선택할 수 있다 (TS-07)', () async {
      final saved = await t.saveCustom(p, kang);
      expect(await t.glyphs.customState(p, kang), saved.after);
      final reverted = await t.glyphs.revertToGenerated(p, kang);
      expect(reverted!.after.selection, GlyphSelection.generated);
      expect(await t.glyphs.revisions(p, kang), hasLength(1));
      final reselected = await t.glyphs.reselectCustom(p, kang);
      expect(reselected!.after, saved.after);
    });

    test('다시 그리면 수정본이 추가되고 이전 수정본은 남는다', () async {
      final first = await t.saveCustom(p, kang);
      final second = await t.saveCustom(p, kang);
      expect(second.before, first.after);
      expect(await t.glyphs.revisions(p, kang), hasLength(2));
      final back = await t.glyphs.setCurrentRevision(p, kang, first.after.revisionId);
      expect(back!.after.revisionId, first.after.revisionId);
    });

    test('TS-06 커스텀 글리프 삭제는 수정 이력 전체를 지우고 선택을 generated로 만든다', () async {
      await t.saveCustom(p, kang);
      await t.saveCustom(p, kang);
      await t.saveCustom(p, gak);
      await t.glyphs.deleteCustom(p, kang);
      expect(await t.glyphs.customState(p, kang), isNull);
      expect(await t.glyphs.revisions(p, kang), isEmpty);
      expect(await t.glyphs.revisions(p, gak), hasLength(1));
    });

    test('선택·삭제·저장마다 glyph_revision이 오른다', () async {
      var rev = (await t.projects.get(p)).glyphRevision;
      Future<void> expectBump() async {
        final now = (await t.projects.get(p)).glyphRevision;
        expect(now, rev + 1);
        rev = now;
      }

      await t.saveCustom(p, kang);
      await expectBump();
      await t.glyphs.revertToGenerated(p, kang);
      await expectBump();
      await t.glyphs.reselectCustom(p, kang);
      await expectBump();
      await t.glyphs.deleteCustom(p, kang);
      await expectBump();
    });
  });

  group('수정 이력 보호 (POL-01)', () {
    test('허용된 경로 밖의 수정본 삭제는 트리거가 막는다', () async {
      await t.saveCustom(p, kang);
      await expectLater(
        exec(t.db, 'DELETE FROM custom_revisions'),
        throwsA(isA<SqliteException>()),
      );
      expect(await t.count('custom_revisions'), 1);
    });

    test('revision_guard 행이 없어도 삭제를 막는다', () async {
      await t.saveCustom(p, kang);
      await exec(t.db, 'DELETE FROM revision_guard');
      await expectLater(
        exec(t.db, 'DELETE FROM custom_revisions'),
        throwsA(isA<SqliteException>()),
      );
    });

    test('revision_guard는 한 행만 허용한다', () async {
      await expectLater(
        exec(t.db, 'INSERT INTO revision_guard VALUES (2, 1)'),
        throwsA(isA<SqliteException>()),
      );
    });

    test('프로젝트 삭제는 수정 이력을 CASCADE로 지우는 허용된 경로다', () async {
      await t.saveCustom(p, kang);
      await t.projects.delete(p);
      expect(await t.count('custom_revisions'), 0);
      expect(await t.count('base_glyphs'), 0);
      expect((await t.db.rows('SELECT allow_revision_delete AS a FROM revision_guard'))
          .single.read<int>('a'), 0);
    });

    test('다른 모든 쓰기 뒤에도 수정본 수가 줄지 않는다', () async {
      await t.saveCustom(p, kang);
      await t.saveCustom(p, gak);
      final before = await t.count('custom_revisions');
      await t.glyphs.revertToGenerated(p, kang);
      await t.glyphs.reselectCustom(p, kang);
      await t.glyphs.saveBaseGlyph(p, 'ㄱ', fixture['ㄱ']!);
      await t.projects.rename(p, '바뀐 이름');
      final memo = await t.memos.create(p);
      await t.memos.updateText(memo, '강');
      await t.memos.delete(memo);
      expect(await t.count('custom_revisions'), before);
    });

    test('현재 수정본은 같은 음절의 것이어야 한다 (복합 외래 키)', () async {
      final other = await t.saveCustom(p, gak);
      await t.saveCustom(p, kang);
      await expectLater(
        exec(t.db,
            'UPDATE custom_glyphs SET current_revision_id = ${other.after.revisionId} '
            'WHERE code_point = $kang'),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('실행 취소 (Spec §9.1)', () {
    test('TS-05 다시 그려 저장 후 실행 취소: 수정본 1이 현재, 2는 이력에 남음', () async {
      final first = await t.saveCustom(p, kang);
      final second = await t.saveCustom(p, kang);
      expect(await t.glyphs.undo(second), isTrue);
      expect(await t.glyphs.customState(p, kang), first.after);
      expect(await t.glyphs.revisions(p, kang), hasLength(2));
    });

    test('첫 저장 실행 취소는 generated로 바꾸고 수정본을 남긴다', () async {
      final first = await t.saveCustom(p, kang);
      expect(await t.glyphs.undo(first), isTrue);
      final state = await t.glyphs.customState(p, kang);
      expect(state!.selection, GlyphSelection.generated);
      expect(await t.glyphs.revisions(p, kang), hasLength(1));
    });

    test('저장 → 삭제 → 실행 취소는 아무것도 바꾸지 않는다', () async {
      final saved = await t.saveCustom(p, kang);
      await t.glyphs.deleteCustom(p, kang);
      expect(await t.glyphs.undo(saved), isFalse);
      expect(await t.glyphs.customState(p, kang), isNull);
      expect(await t.count('custom_revisions'), 0);
    });

    test('상태가 바뀐 뒤의 실행 취소는 거부된다', () async {
      final saved = await t.saveCustom(p, kang);
      await t.glyphs.revertToGenerated(p, kang);
      expect(await t.glyphs.undo(saved), isFalse);
    });
  });

  group('초안 (Spec §4.4)', () {
    test('획이 0개가 되면 초안을 지운다', () async {
      await t.glyphs.saveDraft(p, DraftKind.custom, '$kang', fixture['ㅇ']!);
      expect(await t.glyphs.loadDraft(p, DraftKind.custom, '$kang'), isNotNull);
      await t.glyphs.saveDraft(p, DraftKind.custom, '$kang', const []);
      expect(await t.glyphs.loadDraft(p, DraftKind.custom, '$kang'), isNull);
    });

    test('커스텀 저장은 그 음절의 초안을 지운다', () async {
      await t.glyphs.saveDraft(p, DraftKind.custom, '$kang', fixture['ㅇ']!);
      await t.saveCustom(p, kang);
      expect(await t.glyphs.loadDraft(p, DraftKind.custom, '$kang'), isNull);
    });
  });

  group('원자성과 저장 공간 (FR-01)', () {
    test('TS-15 커스텀 저장 도중 실패하면 수정본도 남지 않고 불변식이 유지된다', () async {
      await exec(t.db, '''
        CREATE TEMP TRIGGER fail_custom BEFORE INSERT ON custom_glyphs
        BEGIN SELECT RAISE(ABORT, 'injected'); END''');
      await expectLater(t.saveCustom(p, kang), throwsA(isA<SqliteException>()));
      expect(await t.count('custom_revisions'), 0);
      expect(await t.count('custom_glyphs'), 0);
    });

    test('TS-16 저장 공간이 가득 차면 SQLITE_FULL로 실패하고 이전 상태는 온전하다', () async {
      final saved = await t.saveCustom(p, kang);
      final pages = (await t.db.rows('PRAGMA page_count')).single.data.values.first as int;
      await exec(t.db, 'PRAGMA max_page_count = $pages');
      Object? error;
      try {
        for (var i = 0; i < 50; i++) {
          await t.saveCustom(p, gak);
        }
      } catch (e) {
        error = e;
      }
      expect(sqliteResultCode(error!), 13); // SQLITE_FULL
      expect(await t.glyphs.customState(p, kang), saved.after);
    });
  });

  test('TS-02 DB를 닫았다 다시 열어도 커스텀 수정 이력과 선택 상태가 유지된다', () async {
    final dir = await Directory.systemTemp.createTemp('hwaeaek_db');
    final file = File('${dir.path}/test.sqlite');
    var db = TestDb.file(file);
    final id = await db.projectWithBaseGlyphs();
    final first = await db.saveCustom(id, kang);
    final second = await db.saveCustom(id, kang);
    await db.glyphs.revertToGenerated(id, kang);
    await db.close();

    db = TestDb.file(file);
    expect(await db.glyphs.customState(id, kang),
        isA<CustomState>()
            .having((s) => s.selection, 'selection', GlyphSelection.generated)
            .having((s) => s.revisionId, 'rev', second.after.revisionId));
    expect((await db.glyphs.revisions(id, kang)).map((r) => r.id),
        [first.after.revisionId, second.after.revisionId]);
    expect((await db.glyphs.baseGlyphs(id)).length, 35);
    await db.close();
  });

  test('TS-20 앱이 아는 세트 버전이 더 높으면 열 때 올리고, 커스텀·선택은 그대로다', () async {
    final saved = await t.saveCustom(p, kang);
    await exec(t.db, "UPDATE projects SET base_set_version = 0 WHERE id = '$p'");
    await t.projects.open(p);
    expect((await t.projects.get(p)).baseSetVersion, latestBaseSetVersion);
    expect(await t.glyphs.customState(p, kang), saved.after);
    expect((await t.projects.get(p)).memoUnlockedAt, isNotNull);
  });
}
