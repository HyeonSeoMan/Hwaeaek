import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 저장소 루트의 Python 검증 도구 (Spec §12). 작업 디렉터리는 `app/`이다.
final pythonTool = File('../.venv-tools/bin/python');

/// 도구가 있으면 true. 없으면 `HWAEAEK_REQUIRE_TOOLS=1`일 때 실패하고,
/// 아니면 테스트를 건너뛴다고 표시한 뒤 false.
bool toolsAvailable() {
  if (pythonTool.existsSync()) return true;
  if (Platform.environment['HWAEAEK_REQUIRE_TOOLS'] == '1') {
    fail('.venv-tools가 없습니다 (HWAEAEK_REQUIRE_TOOLS=1)');
  }
  markTestSkipped('.venv-tools 없음: 외부 검증 생략');
  return false;
}

/// `tools/validate_ttf.py`(OTS + fontTools)로 검증하고 요약 JSON을 돌려준다.
Future<Map<String, dynamic>> validateTtf(File font, {int? expectCmap}) async {
  final result = await Process.run(pythonTool.path, [
    '-I',
    '../tools/validate_ttf.py',
    font.path,
    if (expectCmap != null) ...['--expect-cmap', '$expectCmap'],
  ]);
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return jsonDecode(result.stdout as String) as Map<String, dynamic>;
}
