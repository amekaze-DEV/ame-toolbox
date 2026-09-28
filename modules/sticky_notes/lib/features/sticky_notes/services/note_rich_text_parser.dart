import 'package:flutter/material.dart';

import '../models/note_block.dart';
import '../models/note_inline.dart';

/// 富文本解析 / 渲染分发服务（纯函数）。
///
/// - 纯文本提取：用于卡片预览与导出；
/// - 渲染分发：返回文本块的基础样式；
/// - 行内样式解析：把 [NoteInline] 的样式位（字号 / 颜色）解析为 [TextStyle]。
class NoteRichTextParser {
  const NoteRichTextParser();

  /// 过滤空块：空文本块不渲染；图片块恒可见。
  List<NoteBlock> visibleBlocks(List<NoteBlock> blocks) => blocks
      .where((block) => block is ImageBlock || block.inlines.isNotEmpty)
      .toList();

  /// 提取纯文本（块间换行；空块与图片块忽略）。
  String toPlainText(List<NoteBlock> blocks) {
    final lines = <String>[];
    for (final block in blocks) {
      if (block.inlines.isEmpty) continue;
      lines.add(block.inlines.map((e) => e.text).join());
    }
    return lines.join('\n');
  }

  /// 文本块基础样式；图片块无文本样式，返回 null。
  TextStyle? styleForBlock(NoteBlock block, ThemeData theme) {
    if (block is ImageBlock) return null;
    return theme.textTheme.bodyMedium;
  }

  /// 行内元素最终样式：块基础样式 + 该 run 的行内样式。
  ///
  /// 字号为绝对 pt（仍以 `textTheme` 为默认基线）；颜色为自定义 ARGB，
  /// 未自定义时继承主题色。
  TextStyle inlineStyleOf(NoteInline inline, TextStyle base, ThemeData theme) {
    return base.copyWith(
      fontWeight: inline.bold ? FontWeight.bold : base.fontWeight,
      fontStyle: inline.italic ? FontStyle.italic : base.fontStyle,
      decoration: _decorationOf(inline),
      fontSize: inline.fontSize ?? base.fontSize,
      color: inline.colorValue == null
          ? base.color
          : Color(inline.colorValue!),
    );
  }

  /// 构建整块 [TextSpan]（供富文本控制器 `buildTextSpan` 调用）。
  TextSpan buildTextSpan(
    NoteBlock block,
    List<NoteInline> runs,
    ThemeData theme,
  ) {
    final base = styleForBlock(block, theme) ??
        theme.textTheme.bodyMedium ??
        const TextStyle();
    return TextSpan(
      style: base,
      children: [
        for (final run in runs)
          TextSpan(text: run.text, style: inlineStyleOf(run, base, theme)),
      ],
    );
  }

  /// 下划线 / 删除线组合。
  TextDecoration _decorationOf(NoteInline inline) {
    if (inline.underline && inline.strikethrough) {
      return TextDecoration.combine(
        [TextDecoration.underline, TextDecoration.lineThrough],
      );
    }
    if (inline.underline) return TextDecoration.underline;
    if (inline.strikethrough) return TextDecoration.lineThrough;
    return TextDecoration.none;
  }
}