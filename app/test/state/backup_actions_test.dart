import 'dart:io';

import 'package:flutter/painting.dart' show Rect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/infra/platform/files.dart';
import 'package:hwaeaek/state/backup_actions.dart';
import 'package:hwaeaek/state/export_job.dart';
import 'package:hwaeaek/state/providers.dart';

import '../support/db.dart';

class _Keep implements FileDelivery {
  File? saved;

  @override
  Future<bool> save(File file, {required String fileName}) async {
    saved = file;
    return true;
  }

  @override
  Future<void> share(File file, {required String fileName, Rect? origin}) async {}
}

void main() {
  test('백업 만들기 → 가져오기 동작이 새 프로젝트를 만든다', () async {
    final t = TestDb.memory();
    addTearDown(t.close);
    final p = await t.projectWithBaseGlyphs();
    await t.saveCustom(p, kang);
    final tmp = await Directory.systemTemp.createTemp('hwaeaek_ba');
    final delivery = _Keep();
    File? picked;
    final c = ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(t.db),
        backupTempDirProvider.overrideWith((ref) async => tmp),
        fileDeliveryProvider.overrideWithValue(delivery),
        backupPickerProvider.overrideWithValue(() async => picked),
      ],
    );
    final actions = c.read(backupActionsProvider);

    final file = await actions.createAndSave(p);
    expect(delivery.saved?.path, file.path);
    expect(await actions.pickAndImport(), isNull); // 선택 취소

    picked = file;
    final id = await actions.pickAndImport();
    expect(id, isNotNull);
    expect(await t.glyphs.revisions(id!, kang), hasLength(1));

    picked = File('${tmp.path}/bad.hwaeaek')..writeAsStringSync('nope');
    await expectLater(
      actions.pickAndImport(),
      throwsA(isA<BackupMessage>().having((e) => e.message, 'message', '회애액 백업 파일이 아닙니다.')),
    );
  });
}
