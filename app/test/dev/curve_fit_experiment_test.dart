import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/dev/stroke_fixture.dart';
import 'package:hwaeaek/domain/compose/composer.dart';
import 'package:hwaeaek/domain/font/export.dart';
import 'package:hwaeaek/domain/font/metrics.dart';
import 'package:hwaeaek/domain/font/ttf_writer.dart';
import 'package:hwaeaek/domain/glyph/glyph.dart';
import 'package:hwaeaek/domain/ink/ink.dart';

import '../support/tools.dart';

/// TTF 크기 실험 (OQ-03): 단순화 허용 오차와 2차 곡선 변환별 크기·오차.
/// 오차 = 곡선을 잘게 나눈 점들과 단순화 전 윤곽선 사이의 최대 거리(폰트 단위).

typedef _P = (double, double);

List<_P> _flatten(Contour c) {
  // TrueType 규칙: 연속 off-curve 사이에는 on-curve 중점.
  final pts = <(double, double, bool)>[];
  for (var i = 0; i < c.length; i++) {
    final p = c[i], n = c[(i + 1) % c.length];
    pts.add((p.x.toDouble(), p.y.toDouble(), p.onCurve));
    if (!p.onCurve && !n.onCurve) pts.add(((p.x + n.x) / 2, (p.y + n.y) / 2, true));
  }
  final start = pts.indexWhere((p) => p.$3);
  final seq = [...pts.sublist(start), ...pts.sublist(0, start), pts[start]];
  final out = <_P>[];
  var i = 0;
  while (i < seq.length - 1) {
    final a = seq[i];
    final b = seq[i + 1];
    if (b.$3) {
      out.add((a.$1, a.$2));
      i += 1;
    } else {
      final e = seq[i + 2];
      for (var k = 0; k < 8; k++) {
        final t = k / 8;
        final u = 1 - t;
        out.add((
          u * u * a.$1 + 2 * u * t * b.$1 + t * t * e.$1,
          u * u * a.$2 + 2 * u * t * b.$2 + t * t * e.$2,
        ));
      }
      i += 2;
    }
  }
  return out;
}

double _distToPolygon(_P p, Contour poly) {
  var best = double.infinity;
  for (var i = 0; i < poly.length; i++) {
    final a = poly[i], b = poly[(i + 1) % poly.length];
    final dx = (b.x - a.x).toDouble(), dy = (b.y - a.y).toDouble();
    final len2 = dx * dx + dy * dy;
    var t = len2 == 0 ? 0.0 : ((p.$1 - a.x) * dx + (p.$2 - a.y) * dy) / len2;
    t = t.clamp(0.0, 1.0);
    final x = a.x + t * dx - p.$1, y = a.y + t * dy - p.$2;
    best = math.min(best, math.sqrt(x * x + y * y));
  }
  return best;
}

void main() {
  test('곡선 변환 설정별 TTF 크기와 오차', () async {
    final base = strokeFixture();
    final samples = '가각강닭뷁읽밟한글손쌂꿇왠쳇바퀴'.runes.toList();
    final reference = HangulComposer(base, params: const RuleV1Params(pen: PenStyle(tolerance: 0, curveTolerance: 0)));
    // (직선 단순화 허용 오차, 곡선 맞춤 허용 오차). 곡선이 0이면 직선 다각형.
    const configs = [(2.0, 0.0), (2.0, 1.0), (2.0, 2.0), (2.0, 3.0), (2.0, 4.0)];
    final out = Directory('../build/poc')..createSync(recursive: true);
    final fonts = <String>[];
    for (final (tol, curve) in configs) {
      final composer = HangulComposer(
        base,
        params: RuleV1Params(pen: PenStyle(tolerance: tol, curveTolerance: curve)),
      );
      var maxErr = 0.0, points = 0;
      for (final cp in samples) {
        final g = composer.compose(cp)!, r = reference.compose(cp)!;
        expect(g.contours.length, r.contours.length);
        for (var i = 0; i < g.contours.length; i++) {
          for (final p in _flatten(g.contours[i])) {
            maxErr = math.max(maxErr, _distToPolygon(p, r.contours[i]));
          }
        }
      }
      final glyphs = <int, FontGlyph>{};
      for (final cp in exportCodePoints()) {
        final g = composer.compose(cp)!;
        points += g.pointCount;
        glyphs[cp] = FontGlyph(g, FontMetrics.hangulAdvance);
      }
      final name = 't${tol.round()}_c${curve.round()}';
      final bytes = buildTtf(
        FontSpec(familyName: name, asciiFamilyName: name, created: FontMetrics.fixedCreated, glyphs: glyphs),
      );
      // ignore: avoid_print
      print('tol $tol curve $curve: ${(bytes.length / 1048576).toStringAsFixed(2)}MB, '
          '점 $points, 최대 오차 ${maxErr.toStringAsFixed(1)}');
      fonts.add((File('${out.path}/curve_$name.ttf')..writeAsBytesSync(bytes)).path);
    }
    if (!toolsAvailable()) return;
    await Process.run(pythonTool.path, [
      '-I',
      '../tools/render_sample.py',
      fonts.first,
      '${out.path}/curve_compare.png',
      '닭 뷁 읽 한글 손글씨',
      '--size',
      '110',
      for (final f in fonts.skip(1)) ...['--compare', f],
    ]);
  });
}
