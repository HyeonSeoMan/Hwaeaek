/// TTF 내보내기 계산 (Spec §7.2 4~5단계, 8단계 검증). 백그라운드 isolate에서 돈다.
library;

import 'dart:typed_data';

import '../compose/composer.dart';
import '../glyph/glyph.dart';
import '../glyph/latin_set.dart';
import '../hangul/hangul.dart';
import '../project/snapshot.dart';
import 'metrics.dart';
import 'ttf_reader.dart';
import 'ttf_writer.dart';

class ExportBuild {
  const ExportBuild({
    required this.bytes,
    required this.excluded,
    required this.validCount,
    required this.partCount,
    required this.versionMinor,
  });

  final Uint8List bytes;

  /// cmap에서 뺀 음절·호환 자모 (조합 오류, 손상된 커스텀).
  final List<int> excluded;

  /// 유효 글리프가 있는 호환 자모 + 음절 + 영문·숫자 수.
  final int validCount;

  /// cmap에 없는 부품 글리프 수.
  final int partCount;
  final int versionMinor;
}

/// 내보낼 코드포인트: 호환 자모 51 + 음절 11,172 (POL-04: 빈도와 관계없이 모두).
Iterable<int> exportCodePoints() sync* {
  for (var cp = compatJamoFirst; cp <= compatJamoLast; cp++) {
    yield cp;
  }
  for (var cp = syllableFirst; cp <= syllableLast; cp++) {
    yield cp;
  }
}

/// 진행률 분모. 그리지 않은 영문·숫자는 건너뛰므로 실제 처리 수보다 클 수 있다.
final exportTotal = 51 + syllableCount + latinCodePoints.length;

ExportBuild buildExport(
  GlyphSnapshot snapshot, {
  required int versionMinor,
  required DateTime created,
  void Function(int done)? onProgress,
}) {
  final composer = HangulComposer(snapshot.baseStrokes);
  final glyphs = <int, FontGlyph>{};
  final excluded = <int>[];
  // 자동 생성 음절은 부품(자리에 놓인 자모)을 참조하는 composite로 넣는다.
  // 같은 부품을 여러 음절이 공유하므로 파일이 크게 줄어든다(Spec §7.1).
  final parts = <GlyphOutline>[];
  final partIndex = <String, int>{};
  var done = 0;
  for (final cp in exportCodePoints()) {
    final custom = snapshot.customs[cp];
    if (Syllable.isSyllable(cp) &&
        (custom == null || custom.selection == GlyphSelection.generated)) {
      final composed = composer.composeParts(cp);
      if (composed == null) {
        excluded.add(cp);
      } else {
        glyphs[cp] = FontGlyph.composite(
          GlyphOutline([for (final p in composed) ...p.outline.contours]),
          FontMetrics.hangulAdvance,
          [
            for (final p in composed)
              partIndex.putIfAbsent(p.key, () {
                parts.add(p.outline);
                return parts.length - 1;
              }),
          ],
        );
      }
      if (++done % 500 == 0) onProgress?.call(done);
      continue;
    }
    final g = effectiveGlyph(snapshot, composer.compose, cp);
    // 커스텀 윤곽선도 TTF 한도를 넘으면 뺀다(Spec §7.2 4단계).
    if (g == null ||
        g.isEmpty ||
        g.pointCount > 0xFFFF ||
        g.contours.length > 0x7FFF) {
      excluded.add(cp);
    } else {
      glyphs[cp] = FontGlyph(g, FontMetrics.hangulAdvance);
    }
    if (++done % 500 == 0) onProgress?.call(done);
  }
  // 숫자·문장부호·영문: 그린 글자만 넣는다. 그리지 않은 글자는 선택이므로 제외 목록에 넣지 않는다.
  for (final cp in latinCodePoints) {
    if (!snapshot.baseStrokes.containsKey(String.fromCharCode(cp))) continue;
    final g = composer.compose(cp);
    if (g == null || g.isEmpty || g.pointCount > 0xFFFF) {
      excluded.add(cp);
    } else {
      glyphs[cp] = FontGlyph(g, latinAdvance(g));
    }
    done++;
  }
  onProgress?.call(done);
  final m = snapshot.metadata;
  final bytes = buildTtf(
    FontSpec(
      familyName: m.familyName,
      asciiFamilyName: m.asciiFamilyName,
      styleName: m.styleName,
      versionMinor: versionMinor,
      license: m.license,
      created: created,
      glyphs: glyphs,
      parts: parts,
    ),
  );
  return ExportBuild(
    bytes: bytes,
    excluded: excluded,
    validCount: glyphs.length,
    partCount: parts.length,
    versionMinor: versionMinor,
  );
}

/// 디스크에서 다시 읽은 바이트 검증 (Spec §7.2 8단계).
/// cmap = 1(공백) + 유효 글리프, numGlyphs = cmap + 1(.notdef) + 부품 수.
void verifyExport(Uint8List bytes, ExportBuild build) {
  final info = readTtf(bytes);
  final cmap = 1 + build.validCount;
  if (info.cmap.length != cmap) {
    throw StateError('cmap ${info.cmap.length} != $cmap');
  }
  final numGlyphs = cmap + 1 + build.partCount;
  if (info.numGlyphs != numGlyphs) {
    throw StateError('numGlyphs ${info.numGlyphs} != $numGlyphs');
  }
}
