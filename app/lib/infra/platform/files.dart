/// 내보낸 파일 저장·공유 (Spec §13.2).
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Rect;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 파일을 사용자에게 넘기는 방법. 테스트는 가짜로 바꾼다.
abstract interface class FileDelivery {
  /// 기기에 저장. 사용자가 취소하면 false.
  Future<bool> save(File file, {required String fileName});

  /// OS 공유 시트. [origin]은 iPad 공유 팝오버 위치.
  Future<void> share(File file, {required String fileName, Rect? origin});
}

class PlatformFileDelivery implements FileDelivery {
  const PlatformFileDelivery();

  @override
  Future<bool> save(File file, {required String fileName}) async {
    // iOS는 공유 시트의 "파일에 저장"을 쓴다.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await share(file, fileName: fileName);
      return true;
    }
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: await file.readAsBytes(),
      dialogTitle: '저장할 위치',
    );
    return uri != null;
  }

  @override
  Future<void> share(File file, {required String fileName, Rect? origin}) =>
      SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          fileNameOverrides: [fileName],
          sharePositionOrigin: origin,
        ),
      );
}

/// 앱 문서 폴더의 `exports/` (Spec §7.4).
Future<Directory> defaultExportsRoot() async {
  final docs = await getApplicationDocumentsDirectory();
  return Directory('${docs.path}/exports');
}
