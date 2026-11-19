/// 빈도 순서 provider (Spec §14).
library;

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/hangul/frequency.dart';

/// 라이선스를 확인한 빈도 자산이 있으면 그것을, 없으면 KS X 1001 순서를 쓴다(OQ-05).
final frequencyOrderProvider = FutureProvider<FrequencyOrder>((ref) async {
  try {
    return FrequencyOrder.parse(
      await rootBundle.loadString('assets/frequency/syllables.txt'),
    );
  } on FlutterError {
    return FrequencyOrder.parse(
      await rootBundle.loadString('assets/frequency/ksx1001.txt'),
    );
  }
});
