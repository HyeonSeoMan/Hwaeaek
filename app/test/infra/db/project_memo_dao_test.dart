import 'package:flutter_test/flutter_test.dart';
import 'package:hwaeaek/infra/db/memo_dao.dart';

import '../../support/db.dart';

void main() {
  late TestDb t;
  setUp(() => t = TestDb.memory());
  tearDown(() => t.close());

  test('새 프로젝트의 폰트 이름 기본값', () async {
    final id = await t.projects.create('내 손글씨');
    final p = await t.projects.get(id);
    expect(p.fontFamilyName, '내 손글씨');
    expect(p.fontAsciiName, 'Hwaeaek-${id.substring(0, 8)}');
    expect(p.fontVersionMinor, 0);
    expect(p.memoUnlockedAt, isNull);
  });

  test('이름을 바꿔도 폰트 패밀리 이름은 그대로다', () async {
    final id = await t.projects.create('처음');
    await t.projects.rename(id, '나중');
    final p = await t.projects.get(id);
    expect((p.name, p.fontFamilyName), ('나중', '처음'));
  });

  test('ASCII 이름을 바꾸면 폰트 버전이 0으로 돌아간다 (Spec §7.4)', () async {
    final id = await t.projects.create('x');
    await t.projects.commitFontVersion(id, 7);
    await t.projects.updateFontMetadata(id,
        familyName: 'x', asciiFamilyName: (await t.projects.get(id)).fontAsciiName, license: 'OFL');
    expect((await t.projects.get(id)).fontVersionMinor, 7);
    await t.projects.updateFontMetadata(id,
        familyName: 'x', asciiFamilyName: 'My Hand', license: 'OFL');
    expect((await t.projects.get(id)).fontVersionMinor, 0);
  });

  test('잘못된 ASCII 이름은 거부한다', () async {
    final id = await t.projects.create('x');
    for (final bad in ['', '한글', '(())', 'a' * 32]) {
      expect(
        () => t.projects.updateFontMetadata(id, familyName: 'x', asciiFamilyName: bad, license: ''),
        throwsArgumentError,
        reason: bad,
      );
    }
  });

  test('메모 저장은 한글을 정규화하고 프로젝트 revision·updated_at을 바꾸지 않는다', () async {
    final id = await t.projects.create('x');
    final before = await t.projects.get(id);
    final memo = await t.memos.create(id);
    await t.memos.updateText(memo, String.fromCharCodes([0x1100, 0x1161, 0x11BC]));
    expect((await t.memos.get(memo)).text$, '강');
    final after = await t.projects.get(id);
    expect((after.updatedAt, after.glyphRevision), (before.updatedAt, before.glyphRevision));
  });

  test('메모 삭제 후 실행 취소로 같은 id를 되살린다 (Spec §9.2)', () async {
    final id = await t.projects.create('x');
    final memo = await t.memos.create(id);
    await t.memos.updateText(memo, '안녕');
    final removed = await t.memos.delete(memo);
    expect(await t.count('memos'), 0);
    await t.memos.restore(removed);
    expect((await t.memos.get(memo)).text$, '안녕');
  });

  test('메모 길이 상한', () async {
    final id = await t.projects.create('x');
    final memo = await t.memos.create(id);
    expect(() => t.memos.updateText(memo, 'a' * (maxMemoLength + 1)), throwsArgumentError);
  });

  test('설정 저장', () async {
    final settings = SettingsDao(t.db);
    expect(await settings.getBool(SettingsDao.drawWithFinger), isFalse);
    await settings.setBool(SettingsDao.drawWithFinger, true);
    expect(await settings.getBool(SettingsDao.drawWithFinger), isTrue);
  });
}
