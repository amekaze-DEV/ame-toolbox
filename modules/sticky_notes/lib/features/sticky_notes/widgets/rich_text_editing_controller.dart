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
/// 样式作用范围（与常见编辑器一致）：
/// - **有选区**：直接修改选中文本的格式；
/// - **折叠光标**（无选区）：不修改已输入文本，仅记录「当前输入格式」
///   （pendingStyle），之后输入的文本按该格式渲染，直到再次调整格式为止。
class RichTextEditingController extends TextEditingController {
  RichTextEditingController({List<NoteInline> runs = const []})
      : _runs = NoteInlineRuns.normalize(runs),
        super(text: NoteInlineRuns.textOf(runs));

  static const NoteRichTextParser _parser = NoteRichTextParser();

  List<NoteInline> _runs;
  NoteInline? _pendingStyle;

  /// 当前 runs（文本 + 样式）。
  List<NoteInline> get runs => _runs;

  /// 工具栏选中态：优先取「当前输入格式」，否则取光标所在片段的样式。
  NoteInline get currentStyle {
    final pending = _pendingStyle;
    if (pending != null) return pending;
    if (_runs.isEmpty) return const NoteInline(text: '');
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
    if (newValue.text != value.text) {
      _runs = NoteInlineRuns.replaceTextRange(
        _runs,
        value.text,
        newValue.text,
        // 折叠光标下设定的格式只作用于新输入的文本。
        insertedTemplate: _pendingStyle,
      );
    }
    super.value = newValue;
  }

  /// 应用样式。
  ///
  /// 有选区时修改选中文本；折叠光标时仅作为后续输入格式，
  /// 不改动已输入文本。恢复默认需传对应的 clear 标志。
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

    final selection = this.selection;
    if (selection.isCollapsed) {
      _pendingStyle = template;
    } else {
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