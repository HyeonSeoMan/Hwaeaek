/// 내 폰트로 쓰기 (PRD FR-07, Spec §8).
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/hangul/hangul.dart';
import '../domain/project/snapshot.dart';
import '../infra/db/memo_dao.dart';
import '../state/glyph_actions.dart';
import '../state/memo_font.dart';
import '../state/pending_writes.dart';
import '../state/providers.dart';
import '../state/snapshot.dart';
import 'custom_glyph_flow.dart';
import 'memo_text.dart';

class MemoScreen extends ConsumerStatefulWidget {
  const MemoScreen({super.key, required this.projectId, required this.memoId});

  final String projectId;
  final String memoId;

  @override
  ConsumerState<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends ConsumerState<MemoScreen>
    with WidgetsBindingObserver {
  final _controller = MemoTextController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  Timer? _debounce;
  var _loaded = false;
  String _savedText = '';

  // dispose에서도 마지막 저장을 하므로 ref 대신 미리 잡아 둔다.
  late final PendingWrites _writes = ref.read(pendingWritesProvider);
  late final MemoDao _memos = ref.read(memoDaoProvider);

  MemoFontKey get _key => (projectId: widget.projectId, memoId: widget.memoId);

  @override
  void initState() {
    super.initState();
    _writes;
    _memos;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  Future<void> _load() async {
    final row = await _memos.get(widget.memoId);
    if (!mounted) return;
    _controller.text = row.text$;
    _savedText = row.text$;
    _controller.addListener(_onChanged);
    ref.read(memoFontProvider(_key).notifier).ensure(row.text$);
    setState(() => _loaded = true);
  }

  void _onChanged() {
    ref.read(memoFontProvider(_key).notifier).ensure(_controller.text);
    if (_controller.text == _savedText) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), _flush);
  }

  /// 메모 텍스트 저장 (Spec §4.3): 대기 목록을 거쳐 최신 값만 저장한다.
  void _flush() {
    _debounce?.cancel();
    final text = _controller.text;
    if (text == _savedText) return;
    _savedText = text;
    unawaited(
      _writes.run(
        'memo:${widget.memoId}',
        WriteKind.memo,
        () => _memos.updateText(widget.memoId, text),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _flush();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flush();
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// 선택 영역의 첫 글자, 선택이 없으면 커서 앞 글자 (Spec §8.4).
  int? _target() {
    final sel = _controller.selection;
    final text = _controller.text;
    if (!sel.isValid) return null;
    final at = sel.isCollapsed ? sel.baseOffset - 1 : sel.start;
    if (at < 0 || at >= text.length) return null;
    return text.codeUnitAt(at);
  }

  Future<void> _redraw(int cp) async {
    final selection = _controller.selection;
    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    _flush();
    await redrawSyllable(context, ref, widget.projectId, cp);
    if (!mounted) return;
    // 같은 메모의 같은 스크롤·커서 위치로 돌아온다(FR-07).
    _controller.selection = selection;
    if (_scroll.hasClients) {
      _scroll.jumpTo(offset.clamp(0, _scroll.position.maxScrollExtent));
    }
    _focus.requestFocus();
  }

  Widget _contextMenu(BuildContext context, EditableTextState state) {
    final cp = _target();
    final snapshot = ref
        .read(glyphRendererProvider(widget.projectId))
        ?.snapshot;
    final custom = cp == null ? null : snapshot?.customs[cp];
    final actions = ref.read(glyphActionsProvider(widget.projectId));
    final items = [
      // 호환 자모는 커스텀 대상이 아니다(PRD §9).
      if (cp != null && Syllable.isSyllable(cp)) ...[
        ContextMenuButtonItem(
          label: '‘${String.fromCharCode(cp)}’ 다시 그리기',
          onPressed: () {
            state.hideToolbar();
            _redraw(cp);
          },
        ),
        if (custom?.selection == GlyphSelection.custom)
          ContextMenuButtonItem(
            label: '자동 생성으로 되돌리기',
            onPressed: () async {
              state.hideToolbar();
              await actions.revertToGenerated(cp);
              if (context.mounted) {
                showUndoSnackBar(context, ref, '자동 생성으로 되돌렸습니다 (내 글씨는 보존됨)');
              }
            },
          )
        else if (custom != null)
          ContextMenuButtonItem(
            label: '내 글씨 다시 선택',
            onPressed: () async {
              state.hideToolbar();
              await actions.reselectCustom(cp);
              if (context.mounted) {
                showUndoSnackBar(context, ref, '내 글씨로 다시 바꿨습니다');
              }
            },
          ),
      ],
      ...state.contextMenuButtonItems,
    ];
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    final font = ref.watch(memoFontProvider(_key));
    _controller
      ..knownErrors = font.knownErrors
      ..fallbackColor = Theme.of(context).colorScheme.outline;
    return Scaffold(
      appBar: AppBar(title: const Text('메모')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                key: const Key('memo-field'),
                controller: _controller,
                focusNode: _focus,
                scrollController: _scroll,
                autofocus: true,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                inputFormatters: [
                  HangulNormalizeFormatter(),
                  LengthLimitingTextInputFormatter(maxMemoLength),
                ],
                style: TextStyle(
                  fontFamily: font.family,
                  fontSize: 40,
                  height: 1.35,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '내 글씨로 써 보세요',
                ),
                contextMenuBuilder: _contextMenu,
              ),
            ),
    );
  }
}
