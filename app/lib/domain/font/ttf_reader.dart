/// 기기 안 TTF 검증용 최소 리더 (Spec §7.3).
///
/// 테이블 디렉터리, 테이블 체크섬과 head.checkSumAdjustment, maxp.numGlyphs,
/// cmap format 4를 읽는다. 단순 글리프 디코더는 TS-12 비교에 쓴다.
library;

import 'dart:convert';
import 'dart:typed_data';

import '../decode_error.dart';
import '../glyph/glyph.dart';

class TtfInfo {
  TtfInfo._(this._data, this._tables);

  final ByteData _data;
  final Map<String, ({int offset, int length})> _tables;

  int get numGlyphs => _data.getUint16(_table('maxp').offset + 4);

  /// cmap (3,1) format 4의 코드포인트 → 글리프 ID. 0xFFFF 끝 세그먼트는 뺀다.
  late final Map<int, int> cmap = _readCmap();

  /// 단순 글리프 하나를 윤곽선으로 읽는다. 빈 글리프는 [GlyphOutline.empty].
  GlyphOutline glyph(int glyphId) {
    final head = _table('head').offset;
    final longLoca = _data.getInt16(head + 50) == 1;
    final loca = _table('loca').offset;
    final glyf = _table('glyf').offset;
    int at(int i) => longLoca
        ? _data.getUint32(loca + i * 4)
        : _data.getUint16(loca + i * 2) * 2;
    final start = at(glyphId), end = at(glyphId + 1);
    if (start == end) return GlyphOutline.empty;
    var o = glyf + start;
    final contourCount = _data.getInt16(o);
    if (contourCount < 0) throw const DecodeError('composite glyph');
    o += 10;
    final ends = [
      for (var i = 0; i < contourCount; i++) _data.getUint16(o + i * 2),
    ];
    o += contourCount * 2;
    o += 2 + _data.getUint16(o); // instructions
    final n = ends.isEmpty ? 0 : ends.last + 1;
    final flags = <int>[];
    while (flags.length < n) {
      final f = _data.getUint8(o++);
      flags.add(f);
      if (f & 0x08 != 0) {
        final r = _data.getUint8(o++);
        for (var k = 0; k < r; k++) {
          flags.add(f);
        }
      }
    }
    List<int> coords(int shortBit, int sameBit) {
      final out = <int>[];
      var v = 0;
      for (final f in flags) {
        if (f & shortBit != 0) {
          final d = _data.getUint8(o++);
          v += f & sameBit != 0 ? d : -d;
        } else if (f & sameBit == 0) {
          v += _data.getInt16(o);
          o += 2;
        }
        out.add(v);
      }
      return out;
    }

    final xs = coords(0x02, 0x10);
    final ys = coords(0x04, 0x20);
    final contours = <Contour>[];
    var s = 0;
    for (final e in ends) {
      contours.add([
        for (var i = s; i <= e; i++)
          GlyphPoint(xs[i], ys[i], onCurve: flags[i] & 1 != 0),
      ]);
      s = e + 1;
    }
    return GlyphOutline(contours);
  }

  ({int offset, int length}) _table(String tag) =>
      _tables[tag] ?? (throw DecodeError('missing table $tag'));

  Map<int, int> _readCmap() {
    final base = _table('cmap').offset;
    final count = _data.getUint16(base + 2);
    int? sub;
    for (var i = 0; i < count; i++) {
      final r = base + 4 + i * 8;
      if (_data.getUint16(r) == 3 && _data.getUint16(r + 2) == 1) {
        sub = base + _data.getUint32(r + 4);
      }
    }
    if (sub == null || _data.getUint16(sub) != 4) {
      throw const DecodeError('cmap (3,1) format 4');
    }
    final segX2 = _data.getUint16(sub + 6);
    final ends = sub + 14;
    final starts = ends + segX2 + 2;
    final deltas = starts + segX2;
    final ranges = deltas + segX2;
    final map = <int, int>{};
    for (var i = 0; i < segX2 ~/ 2; i++) {
      final end = _data.getUint16(ends + i * 2);
      final start = _data.getUint16(starts + i * 2);
      final delta = _data.getUint16(deltas + i * 2);
      if (_data.getUint16(ranges + i * 2) != 0) {
        throw const DecodeError('cmap idRangeOffset');
      }
      if (start == 0xFFFF) continue;
      for (var c = start; c <= end; c++) {
        map[c] = (c + delta) & 0xFFFF;
      }
    }
    return map;
  }
}

/// 디렉터리를 읽고 모든 테이블 체크섬과 head.checkSumAdjustment를 검사한다.
TtfInfo readTtf(Uint8List bytes) {
  final d = ByteData.sublistView(bytes);
  if (bytes.length < 12 || d.getUint32(0) != 0x00010000) {
    throw const DecodeError('sfnt version');
  }
  final numTables = d.getUint16(4);
  final tables = <String, ({int offset, int length})>{};
  for (var i = 0; i < numTables; i++) {
    final r = 12 + i * 16;
    final tag = ascii.decode(bytes.sublist(r, r + 4));
    final checksum = d.getUint32(r + 4);
    final offset = d.getUint32(r + 8);
    final length = d.getUint32(r + 12);
    if (offset + length > bytes.length) throw DecodeError('table $tag range');
    var sum = _checksum(bytes, offset, length);
    if (tag == 'head') {
      sum = (sum - d.getUint32(offset + 8)) & 0xFFFFFFFF;
    }
    if (sum != checksum) throw DecodeError('table $tag checksum');
    tables[tag] = (offset: offset, length: length);
  }
  final head = tables['head'] ?? (throw const DecodeError('missing head'));
  final adjustment = d.getUint32(head.offset + 8);
  final whole = (_checksum(bytes, 0, bytes.length) - adjustment) & 0xFFFFFFFF;
  if ((0xB1B0AFBA - whole) & 0xFFFFFFFF != adjustment) {
    throw const DecodeError('checkSumAdjustment');
  }
  return TtfInfo._(d, tables);
}

int _checksum(Uint8List bytes, int offset, int length) {
  var sum = 0;
  for (var i = 0; i < length; i += 4) {
    var word = 0;
    for (var k = 0; k < 4; k++) {
      final idx = offset + i + k;
      word = (word << 8) | (idx < offset + length ? bytes[idx] : 0);
    }
    sum = (sum + word) & 0xFFFFFFFF;
  }
  return sum;
}
