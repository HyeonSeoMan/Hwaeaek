import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../hangul/hangul.dart';
import 'base_glyph_screen.dart';
import 'font_session.dart';
import 'glyph_editor_screen.dart';

/// 내 폰트로 쓰기 (PRD FR-07). PoC: 메모 1개, 저장 없음.
class MemoScreen extends StatefulWidget {
  const MemoScreen({super.key, required this.session});

  final FontSession session;

  @override
  State<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends State<MemoScreen> {
  final _controller = TextEditingController(text: '다람쥐 헌 쳇바퀴에 타고파\n');
  final _focus = FocusNode();
  var _exportCount = 0;

  FontSession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => _session.ensureFontFor(_controller.text));
    _session.ensureFontFor(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// 선택 영역의 첫 글자, 선택이 없으면 커서 앞 글자.
  int? _targetCodePoint() {
    final sel = _controller.selection;
    final text = _controller.text;
    if (!sel.isValid) return null;
    final at = sel.isCollapsed ? sel.baseOffset - 1 : sel.start;
    if (at < 0 || at >= text.length) return null;
    final cp = text.codeUnitAt(at);
    return Syllable.isSyllable(cp) || Syllable.isCompatJamo(cp) ? cp : null;
  }

  Future<void> _redraw(int cp) async {
    final ch = String.fromCharCode(cp);
    final strokes = await Navigator.push(
      context,
      MaterialPageRoute<List<dynamic>>(
        builder: (_) => GlyphEditorScreen(
          title: '‘$ch’ 다시 그리기',
          reference: _session.effectiveGlyph(cp),
        ),
      ),
    );
    if (strokes == null || !mounted) return;
    _session.saveCustom(cp, strokes.cast());
    _focus.requestFocus();
    _showUndo('‘$ch’를 내 글씨로 바꿨습니다');
  }

  void _showUndo(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: '실행 취소', onPressed: _session.undo),
        ),
      );
  }

  Future<void> _export() async {
    final messenger = ScaffoldMessenger.of(context);
    final sw = Stopwatch()..start();
    final result = _session.buildFullFont(exportCount: ++_exportCount);
    final ms = sw.elapsedMilliseconds;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Hwaeaek-Poc-v$_exportCount.ttf');
    await file.writeAsBytes(result.bytes);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '내보내기 ${ms}ms · ${(result.bytes.length / 1048576).toStringAsFixed(1)}MB'
          ' · 제외 ${result.excluded}자\n${file.path}',
        ),
      ),
    );
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], sharePositionOrigin: _shareOrigin()),
    );
  }

  Rect? _shareOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & const Size(1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('회애액 PoC — 내 폰트로 쓰기'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.grid_view),
              label: const Text('기본 글리프'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => BaseGlyphScreen(session: _session),
                ),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.ios_share),
              label: const Text('TTF 내보내기'),
              onPressed: _export,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    fontFamily: _session.fontFamily,
                    fontSize: 44,
                    height: 1.3,
                  ),
                  decoration: const InputDecoration(border: InputBorder.none),
                  contextMenuBuilder: _contextMenu,
                ),
              ),
              Text(
                '동적 폰트: ${_session.fontFamily ?? '-'} · ${_session.lastBuildInfo}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contextMenu(BuildContext context, EditableTextState state) {
    final cp = _targetCodePoint();
    final items = [
      if (cp != null) ...[
        ContextMenuButtonItem(
          label: '‘${String.fromCharCode(cp)}’ 다시 그리기',
          onPressed: () {
            state.hideToolbar();
            _redraw(cp);
          },
        ),
        if (_session.selectionOf(cp) == GlyphSource.custom)
          ContextMenuButtonItem(
            label: '자동 생성으로 되돌리기',
            onPressed: () {
              state.hideToolbar();
              _session.revertToGenerated(cp);
              _showUndo('자동 생성으로 되돌렸습니다 (내 글씨는 보존됨)');
            },
          )
        else if (_session.customOf(cp) != null)
          ContextMenuButtonItem(
            label: '내 글씨 다시 선택',
            onPressed: () {
              state.hideToolbar();
              _session.reselectCustom(cp);
              _showUndo('내 글씨로 다시 바꿨습니다');
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
}
