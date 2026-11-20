import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/dev/stroke_fixture.dart';
import 'package:hwaeaek/domain/compose/composer.dart';
import 'package:hwaeaek/domain/font/export.dart';
import 'package:hwaeaek/domain/font/metrics.dart';
import 'package:hwaeaek/domain/font/ttf_reader.dart';
import 'package:hwaeaek/domain/project/snapshot.dart';

/// 내보내기 크기·시간 측정과 composite 펼침 일치 확인 (OQ-03).
void main() {
  test('내보내기 크기와 시간, composite를 펼친 윤곽선 = 조합 결과', () {
    final snapshot = GlyphSnapshot(
      projectId: 'p',
      revision: 0,
      baseRevision: 0,
      baseSetVersion: 1,
      memoUnlocked: true,
      baseStrokes: strokeFixture(),
      customs: const {},
      metadata: const FontMetadata(familyName: 'x', asciiFamilyName: 'x'),
    );
    final sw = Stopwatch()..start();
    final build = buildExport(snapshot, versionMinor: 1, created: FontMetrics.fixedCreated);
    // ignore: avoid_print
    print('내보내기 ${sw.elapsedMilliseconds}ms, '
        '${(build.bytes.length / 1048576).toStringAsFixed(2)}MB, 부품 ${build.partCount}개');
    verifyExport(build.bytes, build);
    final info = readTtf(build.bytes);
    final composer = HangulComposer(snapshot.baseStrokes);
    for (final s in ['가', '강', '뷁', '닭', '꿇', '힣']) {
      final cp = s.runes.first;
      expect(info.glyph(info.cmap[cp]!).contours, composer.compose(cp)!.contours, reason: s);
    }
  });
}
