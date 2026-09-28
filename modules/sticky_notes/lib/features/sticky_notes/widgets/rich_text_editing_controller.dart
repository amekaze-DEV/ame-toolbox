import 'package:flutter/material.dart';

import '../models/note_block.dart';
import '../models/note_inline.dart';
import '../services/note_inline_runs.dart';
import '../services/note_rich_text_parser.dart';

/// 便签富文本控制器。
///
/// 以 `List<NoteInline>`（runs）为「文本 + 样式」的唯一真源：
/// - 用户编辑文本时，按文本 diff 重建 runs（保留未受影响片段的样式）；
/// - 应用样式时不改动 [value]，只更新 runs 并通知重绘；
/// - 覆写 [buildTextSpan] 按 runs 渲染多段样式。
///
/// 空文本块上点选样式时，样式暂存于 pendingStyle，
/// 待首次输入时播种到新 run 上（支持「先设样式再打字」）。
class RichTextEditingController extends TextEditingController {
  RichTextEditingController({List<NoteInline> runs = const []})
      : _runs = NoteInlineRuns.normalize(runs),
        super(text: NoteInlineRuns.textOf(runs));

  static const NoteRichTextParser _parser = NoteRichTextParser();

  List<NoteInline> _runs;
  NoteInline? _pendingStyle;

  /// 当前 runs（文本 + 样式）。
  List<NoteInline> get runs => _runs;

  /// 工具栏选中态 / 空文本块样式模板：取光标所在 run 的样式。
  NoteInline get currentStyle {
    if (_runs.isEmpty) {
      return _pendingStyle ?? const NoteInline(text: '');
    }
    return NoteInlineRuns.styleAtOffset(_runs, _styleOffset);
  }

  /// 光标偏移（越界时收敛到合法范围）。
  int get _styleOffset {
    final offset = selection.baseOffset;
    if (offset < 0) return 0;
    return offset > text.length ? text.length : offset;
  }

  @override
  set value(TextEditingValue newValue) {
    final oldText = value.text;
    if (newValue.text != oldText) {
      var nextRuns =
          NoteInlineRuns.replaceTextRange(_runs, oldText, newValue.text);
      final pending = _pendingStyle;
      if (pending != null && _runs.isEmpty && nextRuns.isNotEmpty) {
        // 空文本块首次输入：用 pendingStyle 播种新文本样式。
        nextRuns = NoteInlineRuns.overrideStyleAll(nextRuns, pending);
        _pendingStyle = null;
      }
      _runs = nextRuns;
    }
    super.value = newValue;
  }

  /// 对当前选区套用样式。
  ///
  /// 折叠光标（无选区）时作用于光标所在 run；块内无文本时记入
  /// pendingStyle 供随后输入使用。恢复默认需传对应的 clear 标志。
  void applyStyle({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    double? fontSize,
    bool clearFontSize = false,
    int? colorValue,
    bool clearColorValue = false,
  }) {
    final template = currentStyle.copyWith(
      bold: bold,
      italic: italic,
      underline: underline,
      strikethrough: strikethrough,
      fontSize: fontSize,
      clearFontSize: clearFontSize,
      colorValue: colorValue,
      clearColorValue: clearColorValue,
    );

    if (_runs.isEmpty) {
      _pendingStyle = template;
    } else {
      final selection = this.selection;
      _runs = NoteInlineRuns.applyStyleToRange(
        _runs,
        selection.start,
        selection.end,
        template,
      );
      _pendingStyle = null;
    }
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) =>
      _parser.buildTextSpan(
        const ParagraphBlock(inlines: []),
        _runs,
        Theme.of(context),
      );
}