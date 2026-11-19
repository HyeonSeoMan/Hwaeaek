/// 동적 폰트 등록 (Spec §8.1). 같은 이름 재등록은 캐시 문제가 있으므로
/// 등록마다 프로세스 전체에서 새 이름을 쓴다. 등록한 폰트는 해제할 수 없다.
library;

import 'package:flutter/services.dart';

var _familyCounter = 0;

/// 폰트 바이트를 등록하고 패밀리 이름을 돌려준다.
Future<String> registerFont(Uint8List bytes) async {
  final family = 'hw_${++_familyCounter}';
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
  return family;
}
