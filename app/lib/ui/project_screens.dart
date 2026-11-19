/// 프로젝트 목록, 프로젝트 홈, 프로젝트 설정 (PRD FR-01, FR-07, Spec §10).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/font/naming.dart';
import '../domain/hangul/base_set.dart';
import '../infra/db/database.dart';
import '../infra/db/memo_dao.dart';
import '../state/backup_actions.dart';
import '../state/glyph_actions.dart';
import '../state/pending_writes.dart';
import '../state/projects.dart';
import '../state/providers.dart';
import '../state/snapshot.dart';
import 'base_glyph_screen.dart';
import 'export_screen.dart';
import 'frequency_screen.dart';
import 'memo_screen.dart';

Future<String?> _askName(
  BuildContext context, {
  required String title,
  String initial = '',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: '이름'),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);
    final dao = ref.read(projectDaoProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('회애액'),
        actions: [
          IconButton(
            tooltip: '백업 가져오기',
            icon: const Icon(Icons.file_open_outlined),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final id = await ref
                    .read(backupActionsProvider)
                    .pickAndImport();
                if (id == null) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('새 프로젝트로 가져왔습니다')),
                );
                if (context.mounted) openProject(context, id);
              } on BackupMessage catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.message)));
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final name = await _askName(context, title: '새 폰트 프로젝트');
          if (name == null || name.isEmpty) return;
          final id = await dao.create(name);
          if (context.mounted) openProject(context, id);
        },
        icon: const Icon(Icons.add),
        label: const Text('새 프로젝트'),
      ),
      body: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('내 손글씨로 폰트를 만들어 보세요'))
            : ListView(
                children: [
                  for (final p in list)
                    ListTile(
                      title: Text(p.name),
                      subtitle: Text(
                        p.memoUnlockedAt == null
                            ? '기본 글리프 작성 중'
                            : p.fontFamilyName,
                      ),
                      onTap: () => openProject(context, p.id),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'rename') {
                            final name = await _askName(
                              context,
                              title: '이름 바꾸기',
                              initial: p.name,
                            );
                            if (name != null && name.isNotEmpty) {
                              await dao.rename(p.id, name);
                            }
                          } else if (v == 'delete') {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('‘${p.name}’를 삭제할까요?'),
                                content: const Text(
                                  '기본 글리프, 내 글씨, 메모가 모두 지워지고 되돌릴 수 없습니다.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('삭제'),
                                  ),
                                ],
                              ),
                            );
                            if (ok ?? false) {
                              ref.read(undoProvider.notifier).clear();
                              await dao.delete(p.id);
                            }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'rename', child: Text('이름 바꾸기')),
                          PopupMenuItem(value: 'delete', child: Text('삭제')),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

void openProject(BuildContext context, String projectId) => Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (_) => ProjectHomeScreen(projectId: projectId),
  ),
);

class ProjectHomeScreen extends ConsumerStatefulWidget {
  const ProjectHomeScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectHomeScreen> createState() => _ProjectHomeScreenState();
}

class _ProjectHomeScreenState extends ConsumerState<ProjectHomeScreen> {
  String get _id => widget.projectId;

  @override
  void initState() {
    super.initState();
    // 프로젝트를 열 때 세트 버전을 올리고(Spec §3.2), 실행 취소 슬롯을 비운다.
    unawaited(ref.read(projectDaoProvider).open(_id));
    Future.microtask(() => ref.read(undoProvider.notifier).clear());
  }

  Future<void> _openMemo(String memoId) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => MemoScreen(projectId: _id, memoId: memoId),
    ),
  );

  Future<void> _deleteMemo(MemoRow memo) async {
    final dao = ref.read(memoDaoProvider);
    final removed = await dao.delete(memo.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('메모를 삭제했습니다'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '실행 취소',
            onPressed: () => dao.restore(removed),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider(_id)).value;
    final renderer = ref.watch(glyphRendererProvider(_id));
    final memos = ref.watch(memoListProvider(_id)).value ?? const [];
    if (project == null || renderer == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final unlocked = project.memoUnlockedAt != null;
    final required = requiredBaseGlyphs(project.baseSetVersion);
    final done = required
        .where(renderer.snapshot.baseStrokes.containsKey)
        .length;
    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            tooltip: '기본 글리프',
            icon: const Icon(Icons.grid_view),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => BaseGlyphScreen(projectId: _id),
              ),
            ),
          ),
          if (unlocked)
            IconButton(
              tooltip: '자주 쓰는 글자',
              icon: const Icon(Icons.sort_by_alpha),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => FrequencyScreen(projectId: _id),
                ),
              ),
            ),
          if (unlocked)
            IconButton(
              tooltip: 'TTF 내보내기',
              icon: const Icon(Icons.ios_share),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => ExportScreen(projectId: _id),
                ),
              ),
            ),
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ProjectSettingsScreen(projectId: _id),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: unlocked
          ? FloatingActionButton.extended(
              onPressed: () async {
                final id = await ref.read(memoDaoProvider).create(_id);
                await _openMemo(id);
              },
              icon: const Icon(Icons.edit_note),
              label: const Text('새 메모'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          if (done < required.length)
            Card(
              margin: const EdgeInsets.all(16),
              child: ListTile(
                title: Text('기본 글리프 $done / ${required.length}'),
                subtitle: Text(
                  unlocked
                      ? '앱 업데이트로 새로 필요한 글리프가 있습니다'
                      : '필수 글리프를 모두 쓰면 내 글씨로 메모를 쓸 수 있습니다',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => BaseGlyphScreen(projectId: _id),
                  ),
                ),
              ),
            ),
          for (final m in memos)
            Dismissible(
              key: ValueKey(m.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                color: Theme.of(context).colorScheme.errorContainer,
                child: const Icon(Icons.delete_outline),
              ),
              onDismissed: (_) => _deleteMemo(m),
              child: ListTile(
                title: Text(
                  m.text$.trim().isEmpty
                      ? '(빈 메모)'
                      : m.text$.trim().split('\n').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: unlocked ? () => _openMemo(m.id) : null,
              ),
            ),
        ],
      ),
    );
  }
}

class ProjectSettingsScreen extends ConsumerStatefulWidget {
  const ProjectSettingsScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectSettingsScreen> createState() =>
      _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends ConsumerState<ProjectSettingsScreen> {
  final _family = TextEditingController();
  final _ascii = TextEditingController();
  final _license = TextEditingController();
  final _form = GlobalKey<FormState>();
  var _finger = false;
  var _loaded = false;
  var _backingUp = false;

  Future<void> _backup() async {
    setState(() => _backingUp = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(backupActionsProvider).createAndSave(widget.projectId);
    } on BackupMessage catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(() async {
      final p = await ref.read(projectDaoProvider).get(widget.projectId);
      final finger = await ref
          .read(settingsDaoProvider)
          .getBool(SettingsDao.drawWithFinger);
      if (!mounted) return;
      setState(() {
        _family.text = p.fontFamilyName;
        _ascii.text = p.fontAsciiName;
        _license.text = p.fontLicense;
        _finger = finger;
        _loaded = true;
      });
    }());
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await ref
        .read(pendingWritesProvider)
        .run(
          'meta:${widget.projectId}',
          WriteKind.other,
          () => ref
              .read(projectDaoProvider)
              .updateFontMetadata(
                widget.projectId,
                familyName: _family.text.trim(),
                asciiFamilyName: _ascii.text.trim(),
                license: _license.text.trim(),
              ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('설정'),
      actions: [
        TextButton(onPressed: _loaded ? _save : null, child: const Text('저장')),
      ],
    ),
    body: !_loaded
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('폰트 이름', style: Theme.of(context).textTheme.titleSmall),
                TextFormField(
                  controller: _family,
                  decoration: const InputDecoration(labelText: '폰트 이름 (한글 가능)'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? '이름을 입력해 주세요' : null,
                ),
                TextFormField(
                  controller: _ascii,
                  decoration: const InputDecoration(
                    labelText: '영문 이름',
                    helperText: '설치한 프로그램이 쓰는 이름입니다. 바꾸면 폰트 버전이 처음부터 시작합니다.',
                  ),
                  validator: (v) => asciiFamilyNameError((v ?? '').trim()),
                ),
                TextFormField(
                  controller: _license,
                  decoration: const InputDecoration(labelText: '라이선스 문구 (선택)'),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('손가락으로도 그리기'),
                  subtitle: const Text('펜을 쓰는 중에도 손가락 입력을 획으로 받습니다'),
                  value: _finger,
                  onChanged: (v) async {
                    setState(() => _finger = v);
                    await ref
                        .read(settingsDaoProvider)
                        .setBool(SettingsDao.drawWithFinger, v);
                  },
                ),
                const SizedBox(height: 24),
                Text('백업', style: Theme.of(context).textTheme.titleSmall),
                const Text(
                  '기본 글리프, 내 글씨와 수정 이력, 메모를 파일 하나로 저장합니다. '
                  '앱을 지우거나 기기를 바꿀 때 이 파일로 되살릴 수 있습니다.',
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: _backingUp
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.backup_outlined),
                  label: const Text('백업 만들기'),
                  onPressed: _backingUp ? null : _backup,
                ),
              ],
            ),
          ),
  );
}
