/// 쓰기 실패 대기 목록 (Spec §4.3, PRD FR-01).
///
/// 실패한 쓰기를 메모리에 두고 1·2·4…최대 30초 간격으로 다시 시도한다.
/// 같은 대상의 새 쓰기는 그 대상의 대기 항목 뒤에서 기다리며, 메모·초안은
/// 최신 값 하나로 합친다. 다른 대상은 영향을 받지 않는다.
library;

import 'dart:async';

import 'package:drift/drift.dart' show CouldNotRollBackException;
import 'package:sqlite3/sqlite3.dart' show SqliteException;

enum WriteKind {
  /// 기본 글리프, 커스텀, 선택 상태, 커스텀 삭제. 대기 중이면 내보내기를 막는다.
  glyph,

  /// 최신 값 하나로 합친다.
  memo,
  draft,
  other,
}

enum WriteBanner {
  none,

  /// "저장하지 못했습니다. 다시 시도하는 중…"
  retrying,

  /// "저장 공간이 부족합니다. 공간을 확보하거나 백업을 내보내 주세요"
  storageFull,
}

class _Item {
  _Item(this.kind, this.op);

  final WriteKind kind;
  Future<void> Function() op;
  final done = Completer<void>();
  var failures = 0;
  Object? lastError;
}

const _sqliteFull = 13;

/// SQLite 결과 코드. SQLITE_FULL처럼 SQLite가 트랜잭션을 스스로 롤백한 경우
/// Drift는 원래 오류를 [CouldNotRollBackException.cause]에 감싸 던진다.
int? sqliteResultCode(Object error) => switch (error) {
  SqliteException(:final resultCode) => resultCode,
  CouldNotRollBackException(:final cause) => sqliteResultCode(cause),
  _ => null,
};

class PendingWrites {
  PendingWrites({Duration Function(int failures)? backoff})
    : _backoff = backoff ?? _defaultBackoff;

  final Duration Function(int failures) _backoff;
  final _queues = <String, List<_Item>>{};
  final _timers = <String, Timer>{};
  final _banner = StreamController<WriteBanner>.broadcast();
  var _current = WriteBanner.none;

  static Duration _defaultBackoff(int failures) =>
      Duration(seconds: [1 << (failures - 1), 30].reduce((a, b) => a < b ? a : b));

  WriteBanner get banner => _current;
  Stream<WriteBanner> get bannerChanges => _banner.stream;

  bool get hasPendingGlyphWrites => _queues.values.any(
    (q) => q.any((i) => i.kind == WriteKind.glyph),
  );

  bool isPending(String key) => _queues[key]?.isNotEmpty ?? false;

  /// [key] 대상에 쓰기를 실행한다. 반환 Future는 결국 커밋될 때 끝난다.
  /// 처음 시도가 실패하면 대기 목록에 들어가며, 배너가 켜진다.
  Future<void> run(String key, WriteKind kind, Future<void> Function() op) {
    final queue = _queues[key];
    if (queue != null && queue.isNotEmpty) {
      final coalesce = kind == WriteKind.memo || kind == WriteKind.draft;
      // 실행 중이 아닌(맨 앞이 아닌) 마지막 항목과 합친다.
      if (coalesce && queue.length > 1 && queue.last.kind == kind) {
        queue.last.op = op;
        return queue.last.done.future;
      }
      final item = _Item(kind, op);
      queue.add(item);
      return item.done.future;
    }
    final item = _Item(kind, op);
    _queues[key] = [item];
    _attempt(key);
    return item.done.future;
  }

  /// 아직 커밋되지 않은 [key]의 대기 항목을 지운다(실행 취소, Spec §9.1).
  /// 지운 항목이 있으면 true. 지운 항목의 Future는 끝나지 않는다.
  bool cancel(String key) {
    final queue = _queues.remove(key);
    _timers.remove(key)?.cancel();
    _updateBanner();
    return queue != null && queue.isNotEmpty;
  }

  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _banner.close();
  }

  Future<void> _attempt(String key) async {
    final queue = _queues[key];
    if (queue == null || queue.isEmpty) return;
    final item = queue.first;
    try {
      await item.op();
    } catch (e) {
      // 시도 중에 취소되었으면 아무것도 하지 않는다.
      if (!identical(_queues[key], queue)) return;
      item
        ..failures += 1
        ..lastError = e;
      _updateBanner();
      _timers[key] = Timer(_backoff(item.failures), () {
        _timers.remove(key);
        _attempt(key);
      });
      return;
    }
    if (!identical(_queues[key], queue)) return;
    queue.removeAt(0);
    item.done.complete();
    if (queue.isEmpty) {
      _queues.remove(key);
      _updateBanner();
    } else {
      await _attempt(key);
    }
  }

  void _updateBanner() {
    final failing = [
      for (final q in _queues.values)
        if (q.isNotEmpty && q.first.failures > 0) q.first,
    ];
    final next = failing.isEmpty
        ? WriteBanner.none
        : failing.any(
            (i) =>
                i.failures >= 3 ||
                (i.lastError != null &&
                    sqliteResultCode(i.lastError!) == _sqliteFull),
          )
        ? WriteBanner.storageFull
        : WriteBanner.retrying;
    if (next != _current) {
      _current = next;
      if (!_banner.isClosed) _banner.add(next);
    }
  }
}
