/// HWS1 획 직렬화 (Spec §4.2). 리틀 엔디언, 점 하나 24바이트.
library;

import 'dart:convert';
import 'dart:typed_data';

import '../decode_error.dart';
import 'ink.dart';
import 'quantize.dart';

/// 입력 상한 (Spec §3.2).
abstract final class InkLimits {
  static const maxStrokes = 200;
  static const maxPointsPerStroke = 5000;
  static const maxPointsPerGlyph = 20000;
  static const coordinateMin = -32768.0;
  static const coordinateMax = 32767.0;
}

const _magic = 'HWS1';
const _pointBytes = 24;

Uint8List encodeHws1(List<InkStroke> strokes) {
  _checkLimits(strokes.length, [for (final s in strokes) s.points.length]);
  final total = strokes.fold(0, (n, s) => n + s.points.length);
  final out = ByteData(4 + 2 + strokes.length * 4 + total * _pointBytes);
  var o = 0;
  for (final c in ascii.encode(_magic)) {
    out.setUint8(o++, c);
  }
  out.setUint16(o, strokes.length, Endian.little);
  o += 2;
  for (final s in strokes) {
    out.setUint32(o, s.points.length, Endian.little);
    o += 4;
    for (final p in s.points) {
      out
        ..setFloat32(o, p.x, Endian.little)
        ..setFloat32(o + 4, p.y, Endian.little)
        ..setFloat32(o + 8, p.pressure ?? double.nan, Endian.little)
        ..setFloat32(o + 12, p.tilt ?? double.nan, Endian.little)
        ..setFloat32(o + 16, p.orientation ?? double.nan, Endian.little)
        ..setUint32(o + 20, p.t, Endian.little);
      o += _pointBytes;
    }
  }
  return out.buffer.asUint8List();
}

/// 형식과 상한을 모두 검사한다. 위반하면 [DecodeError].
List<InkStroke> decodeHws1(Uint8List bytes) {
  final d = ByteData.sublistView(bytes);
  if (bytes.length < 6 || ascii.decode(bytes.sublist(0, 4), allowInvalid: true) != _magic) {
    throw const DecodeError('HWS1 magic');
  }
  var o = 4;
  final strokeCount = d.getUint16(o, Endian.little);
  o += 2;
  if (strokeCount < 1 || strokeCount > InkLimits.maxStrokes) {
    throw DecodeError('HWS1 strokeCount $strokeCount');
  }
  final strokes = <InkStroke>[];
  var total = 0;
  for (var i = 0; i < strokeCount; i++) {
    if (o + 4 > bytes.length) throw const DecodeError('HWS1 truncated');
    final n = d.getUint32(o, Endian.little);
    o += 4;
    total += n;
    if (n < 1 || n > InkLimits.maxPointsPerStroke || total > InkLimits.maxPointsPerGlyph) {
      throw DecodeError('HWS1 pointCount $n');
    }
    if (o + n * _pointBytes > bytes.length) {
      throw const DecodeError('HWS1 truncated');
    }
    final points = <InkPoint>[];
    var lastT = 0;
    for (var k = 0; k < n; k++) {
      final x = d.getFloat32(o, Endian.little);
      final y = d.getFloat32(o + 4, Endian.little);
      final pressure = d.getFloat32(o + 8, Endian.little);
      final tilt = d.getFloat32(o + 12, Endian.little);
      final orientation = d.getFloat32(o + 16, Endian.little);
      final t = d.getUint32(o + 20, Endian.little);
      o += _pointBytes;
      if (!_coord(x) || !_coord(y)) throw const DecodeError('HWS1 coordinate');
      if (!pressure.isNaN && (pressure < 0 || pressure > 1)) {
        throw const DecodeError('HWS1 pressure');
      }
      if (tilt.isInfinite || orientation.isInfinite) {
        throw const DecodeError('HWS1 tilt');
      }
      if (t < lastT) throw const DecodeError('HWS1 time');
      lastT = t;
      points.add(
        quantizedPoint(
          x,
          y,
          pressure: pressure.isNaN ? null : pressure,
          tilt: tilt.isNaN ? null : tilt,
          orientation: orientation.isNaN ? null : orientation,
          t: t,
        ),
      );
    }
    strokes.add(InkStroke(points));
  }
  if (o != bytes.length) throw const DecodeError('HWS1 trailing bytes');
  return strokes;
}

bool _coord(double v) =>
    v.isFinite && v >= InkLimits.coordinateMin && v <= InkLimits.coordinateMax;

void _checkLimits(int strokeCount, List<int> pointCounts) {
  if (strokeCount < 1 || strokeCount > InkLimits.maxStrokes) {
    throw ArgumentError.value(strokeCount, 'strokeCount');
  }
  var total = 0;
  for (final n in pointCounts) {
    total += n;
    if (n < 1 || n > InkLimits.maxPointsPerStroke) {
      throw ArgumentError.value(n, 'pointCount');
    }
  }
  if (total > InkLimits.maxPointsPerGlyph) {
    throw ArgumentError.value(total, 'totalPoints');
  }
}
