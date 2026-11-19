import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/domain/glyph/glyph.dart';
import 'package:hwaeaek/domain/ink/ink.dart';
import 'package:hwaeaek/domain/project/snapshot.dart';
import 'package:hwaeaek/state/glyph_actions.dart';
import 'package:hwaeaek/state/pending_writes.dart';
import 'package:hwaeaek/state/providers.dart';
import 'package:hwaeaek/state/snapshot.dart';

import '../support/db.dart';

/// 픽스처 ㄱ의 모양을 바꾼다(마지막 점만 이동, 평행 이동은 조합에서 사라진다).
List<InkStroke> _reshapedGiyeok() {
  final g = fixture['ㄱ']!.first.points;
  return [
    InkStroke([...g.take(g.length - 1), g.last.movedTo(g.last.x - 150, g.last.y + 200)]),
  ];
}

String _str(GlyphOutline? o) => o!.contours.toString();

void main() {
  late TestDb t;
  late ProviderContainer c;
  late String p;

  setUp(() async {
    t = TestDb.memory();
    p = await t.projectWithBaseGlyphs();
    c = ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(t.db),
        pendingWritesProvider.overrideWithValue(
          PendingWrites(backoff: (_) => const Duration(milliseconds: 20)),
        ),
      ],
    );
  });
  tearDown(() => t.close());

  /// 렌더러가 [test]를 만족할 때까지 기다린다(스냅샷은 DB 스트림으로 비동기 갱신).
  Future<GlyphRenderer> rendererWhere(bool Function(GlyphRenderer r) test) async {
    final done = Completer<GlyphRenderer>();
    final sub = c.listen<GlyphRenderer?>(glyphRendererProvider(p), (_, next) {
      if (next != null && test(next) && !done.isCompleted) done.complete(next);
    }, fireImmediately: true);
    try {
      return await done.future.timeout(const Duration(seconds: 5));
    } finally {
      sub.close();
    }
  }

  Future<GlyphRenderer> rendererAtLeast(int revision) =>
      rendererWhere((r) => r.snapshot.revision >= revision);

  test('TS-01 커스텀 강은 기본 글리프 ㄱ을 바꿔도 유지되고, ㄱ을 쓰는 자동 생성 음절만 바뀐다', () async {
    final actions = c.read(glyphActionsProvider(p));
    final kangCustom = fixture['ㅇ']!;
    await actions.saveCustom(kang, kangCustom);
    final before = await rendererWhere((r) => r.snapshot.customs.containsKey(kang));
    final ga = '가'.runes.first, na = '나'.runes.first;
    final beforeGa = _str(before.outline(ga));
    final beforeNa = _str(before.outline(na));
    final kangOutline = _str(before.outline(kang));
    expect(kangOutline, _str(strokesToOutline(kangCustom)));

    await actions.saveBaseGlyph('ㄱ', _reshapedGiyeok());
    final after = await rendererAtLeast(before.snapshot.revision + 1);
    expect(_str(after.outline(kang)), kangOutline);
    expect(_str(after.outline(ga)), isNot(beforeGa));
    expect(_str(after.outline(na)), beforeNa);
  });

  test('TS-05 다시 그려 저장 후 실행 취소: 수정본 1이 다시 보인다', () async {
    final actions = c.read(glyphActionsProvider(p));
    final first = fixture['ㅇ']!;
    final second = fixture['ㅁ']!;
    await actions.saveCustom(kang, first);
    await actions.saveCustom(kang, second);
    final saved = await rendererWhere(
      (r) => _str(r.outline(kang)) == _str(strokesToOutline(second)),
    );
    expect(await c.read(undoProvider.notifier).undo(), UndoResult.undone);
    final undone = await rendererAtLeast(saved.snapshot.revision + 1);
    expect(_str(undone.outline(kang)), _str(strokesToOutline(first)));
    expect(await t.glyphs.revisions(p, kang), hasLength(2));
    expect(c.read(undoProvider), isNull);
  });

  test('자동 생성으로 되돌리면 조합 결과가 보이고, 다시 선택하면 커스텀이 보인다', () async {
    final actions = c.read(glyphActionsProvider(p));
    final generated = _str((await rendererAtLeast(0)).outline(kang));
    await actions.saveCustom(kang, fixture['ㅇ']!);
    await actions.revertToGenerated(kang);
    final reverted = await rendererWhere(
      (r) => r.snapshot.customs[kang]?.selection == GlyphSelection.generated,
    );
    expect(_str(reverted.outline(kang)), generated);
    await actions.reselectCustom(kang);
    final reselected = await rendererWhere(
      (r) => r.snapshot.customs[kang]?.selection == GlyphSelection.custom,
    );
    expect(_str(reselected.outline(kang)), _str(strokesToOutline(fixture['ㅇ']!)));
  });

  test('조합 캐시는 커스텀 변경에는 유지되고 기본 글리프 변경 때만 새로 만든다 (Spec §6.5)', () async {
    final actions = c.read(glyphActionsProvider(p));
    final r0 = await rendererAtLeast(0);
    r0.outline('가'.runes.first);
    await actions.saveCustom(kang, fixture['ㅇ']!);
    final r1 = await rendererAtLeast(r0.snapshot.revision + 1);
    expect(identical(r1.composer, r0.composer), isTrue);
    await actions.saveBaseGlyph('ㄱ', _reshapedGiyeok());
    final r2 = await rendererAtLeast(r1.snapshot.revision + 1);
    expect(identical(r2.composer, r1.composer), isFalse);
  });

  test('메모 쓰기는 스냅샷을 다시 만들지 않는다', () async {
    final snapshots = <GlyphSnapshot>[];
    final sub = c.listen<GlyphRenderer?>(glyphRendererProvider(p), (_, next) {
      if (next != null) snapshots.add(next.snapshot);
    }, fireImmediately: true);
    await rendererAtLeast(0);
    final count = snapshots.length;
    final memo = await t.memos.create(p);
    await t.memos.updateText(memo, '안녕');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(snapshots.length, count);
    sub.close();
  });

  test('대기 중인 커스텀 저장의 실행 취소는 대기 항목을 지우고 아무것도 쓰지 않는다 (Spec §9.1)', () async {
    await exec(t.db, '''
      CREATE TEMP TRIGGER fail_custom BEFORE INSERT ON custom_glyphs
      BEGIN SELECT RAISE(ABORT, 'injected'); END''');
    final actions = c.read(glyphActionsProvider(p));
    unawaited(actions.saveCustom(kang, fixture['ㅇ']!));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final writes = c.read(pendingWritesProvider);
    expect(writes.isPending(actions.customKey(kang)), isTrue);
    expect(writes.banner, WriteBanner.retrying);
    expect(await c.read(undoProvider.notifier).undo(), UndoResult.cancelledPending);
    await exec(t.db, 'DROP TRIGGER fail_custom');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(await t.count('custom_revisions'), 0);
    expect(writes.banner, WriteBanner.none);
  });

  test('커스텀 삭제는 실행 취소 슬롯을 비운다', () async {
    final actions = c.read(glyphActionsProvider(p));
    await actions.saveCustom(kang, fixture['ㅇ']!);
    expect(c.read(undoProvider), isNotNull);
    await actions.deleteCustom(kang);
    expect(c.read(undoProvider), isNull);
  });
}
