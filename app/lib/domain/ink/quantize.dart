/// f32 양자화 (Spec §5). 메모리와 HWS1이 같은 값을 갖게 해 저장 전후 조합
/// 결과가 같도록 한다.
library;

import 'dart:typed_data';

import 'ink.dart';

final _f32 = Float32List(1);

double toF32(double v) {
  _f32[0] = v;
  return _f32[0];
}

double? _opt(double? v) => v == null ? null : toF32(v);

/// 포인터 입력에서 점을 만들 때 쓴다.
InkPoint quantizedPoint(
  double x,
  double y, {
  double? pressure,
  double? tilt,
  double? orientation,
  int t = 0,
}) => InkPoint(
  toF32(x),
  toF32(y),
  pressure: _opt(pressure),
  tilt: _opt(tilt),
  orientation: _opt(orientation),
  t: t,
);

InkStroke quantizedStroke(InkStroke s) => InkStroke([
  for (final p in s.points)
    quantizedPoint(
      p.x,
      p.y,
      pressure: p.pressure,
      tilt: p.tilt,
      orientation: p.orientation,
      t: p.t,
    ),
]);
