/// HWO1 윤곽선 직렬화 (Spec §4.2). 리틀 엔디언.
library;

import 'dart:convert';
import 'dart:typed_data';

import '../decode_error.dart';
import 'glyph.dart';

const _magic = 'HWO1';
const maxContours = 10000;

Uint8List encodeHwo1(GlyphOutline outline) {
  final contours = outline.contours;
  if (contours.length > maxContours) {
    throw ArgumentError.value(contours.length, 'contourCount');
  }
  final b = BytesBuilder(copy: false)..add(ascii.encode(_magic));
  final tmp = ByteData(4);
  void u16(int v) {
    tmp.setUint16(0, v, Endian.little);
    b.add(tmp.buffer.asUint8List(0, 2).toList());
  }

  void i16(int v) {
    if (v < -32768 || v > 32767) throw RangeError.value(v, 'i16');
    tmp.setInt16(0, v, Endian.little);
    b.add(tmp.buffer.asUint8List(0, 2).toList());
  }

  u16(contours.length);
  for (final c in contours) {
    if (c.length < 3 || c.length > 0xFFFF) {
      throw ArgumentError.value(c.length, 'pointCount');
    }
    u16(c.length);
    for (final p in c) {
      i16(p.x);
      i16(p.y);
      b.addByte(p.onCurve ? 1 : 0);
    }
  }
  return b.toBytes();
}

GlyphOutline decodeHwo1(Uint8List bytes) {
  final d = ByteData.sublistView(bytes);
  if (bytes.length < 6 || ascii.decode(bytes.sublist(0, 4), allowInvalid: true) != _magic) {
    throw const DecodeError('HWO1 magic');
  }
  var o = 4;
  final count = d.getUint16(o, Endian.little);
  o += 2;
  if (count > maxContours) throw DecodeError('HWO1 contourCount $count');
  final contours = <Contour>[];
  for (var i = 0; i < count; i++) {
    if (o + 2 > bytes.length) throw const DecodeError('HWO1 truncated');
    final n = d.getUint16(o, Endian.little);
    o += 2;
    if (n < 3) throw DecodeError('HWO1 pointCount $n');
    if (o + n * 5 > bytes.length) throw const DecodeError('HWO1 truncated');
    final c = <GlyphPoint>[];
    for (var k = 0; k < n; k++) {
      final flags = d.getUint8(o + 4);
      if (flags & ~1 != 0) throw const DecodeError('HWO1 flags');
      c.add(
        GlyphPoint(
          d.getInt16(o, Endian.little),
          d.getInt16(o + 2, Endian.little),
          onCurve: flags == 1,
        ),
      );
      o += 5;
    }
    contours.add(c);
  }
  if (o != bytes.length) throw const DecodeError('HWO1 trailing bytes');
  return GlyphOutline(contours);
}
