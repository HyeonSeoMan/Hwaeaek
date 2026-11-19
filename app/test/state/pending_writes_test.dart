import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show CouldNotRollBackException;
import 'package:hwaeaek/state/pending_writes.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

/// 처음 [failTimes]번은 실패하는 쓰기.
class _FlakyWrite {
  _FlakyWrite(this.failTimes, this.log, this.label);

  int failTimes;
  final List<String> log;
  final String label;

  Future<void> call() async {
    if (failTimes > 0) {
      failTimes--;
      throw StateError('disk');
    }
    log.add(label);
  }
}

void main() {
  test('실패하면 배너를 켜고 백오프 후 다시 시도해 커밋한다 (FR-01)', () {
    fakeAsync((async) {
      final w = PendingWrites();
      final log = <String>[];
      var done = false;
      w.run('glyph:강', WriteKind.glyph, _FlakyWrite(2, log, 'A').call).then((_) => done = true);
      async.flushMicrotasks();
      expect(w.banner, WriteBanner.retrying);
      expect(w.hasPendingGlyphWrites, isTrue);
      async.elapse(const Duration(seconds: 1)); // 2번째 실패
      expect(done, isFalse);
      async.elapse(const Duration(seconds: 2)); // 성공
      expect(done, isTrue);
      expect(log, ['A']);
      expect(w.banner, WriteBanner.none);
      expect(w.hasPendingGlyphWrites, isFalse);
    });
  });

  test('같은 대상의 새 쓰기는 대기 항목 뒤에서 순서대로 실행된다', () {
    fakeAsync((async) {
      final w = PendingWrites();
      final log = <String>[];
      w.run('glyph:강', WriteKind.glyph, _FlakyWrite(1, log, 'A').call);
      w.run('glyph:강', WriteKind.glyph, _FlakyWrite(0, log, 'B').call);
      w.run('glyph:각', WriteKind.glyph, _FlakyWrite(0, log, 'C').call);
      async.flushMicrotasks();
      expect(log, ['C']); // 다른 대상은 막히지 않는다
      async.elapse(const Duration(seconds: 1));
      expect(log, ['C', 'A', 'B']);
    });
  });

  test('메모 쓰기는 최신 값 하나로 합친다', () {
    fakeAsync((async) {
      final w = PendingWrites();
      final log = <String>[];
      w.run('memo:1', WriteKind.memo, _FlakyWrite(1, log, 'v1').call);
      w.run('memo:1', WriteKind.memo, _FlakyWrite(0, log, 'v2').call);
      w.run('memo:1', WriteKind.memo, _FlakyWrite(0, log, 'v3').call);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));
      expect(log, ['v1', 'v3']);
      expect(w.hasPendingGlyphWrites, isFalse);
    });
  });

  test('연속 3회 실패하면 저장 공간 부족 배너로 바꾸고 재시도를 계속한다', () {
    fakeAsync((async) {
      final w = PendingWrites();
      final log = <String>[];
      w.run('draft:x', WriteKind.draft, _FlakyWrite(3, log, 'D').call);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1 + 2));
      expect(w.banner, WriteBanner.storageFull);
      async.elapse(const Duration(seconds: 4));
      expect(log, ['D']);
      expect(w.banner, WriteBanner.none);
    });
  });

  test('백오프는 1, 2, 4… 최대 30초', () {
    fakeAsync((async) {
      final w = PendingWrites();
      final log = <String>[];
      w.run('k', WriteKind.other, _FlakyWrite(7, log, 'X').call);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1 + 2 + 4 + 8 + 16 + 30 - 1));
      expect(log, isEmpty);
      async.elapse(const Duration(seconds: 1 + 30));
      expect(log, ['X']);
    });
  });

  test('대기 중인 쓰기의 실행 취소는 대기 항목을 지운다 (Spec §9.1)', () {
    fakeAsync((async) {
      final w = PendingWrites();
      final log = <String>[];
      w.run('glyph:강', WriteKind.glyph, _FlakyWrite(1, log, 'A').call);
      async.flushMicrotasks();
      expect(w.cancel('glyph:강'), isTrue);
      async.elapse(const Duration(seconds: 5));
      expect(log, isEmpty);
      expect(w.banner, WriteBanner.none);
      expect(w.hasPendingGlyphWrites, isFalse);
    });
  });

  test('SQLITE_FULL(롤백 실패로 감싸진 경우 포함)은 즉시 저장 공간 부족 배너', () {
    fakeAsync((async) {
      final w = PendingWrites();
      w.run('k', WriteKind.other, () async {
        throw CouldNotRollBackException(
          SqliteException(extendedResultCode: 13, message: 'database or disk is full'),
          StackTrace.empty,
          StateError('no transaction'),
        );
      });
      async.flushMicrotasks();
      expect(w.banner, WriteBanner.storageFull);
      w.dispose();
    });
  });
}
