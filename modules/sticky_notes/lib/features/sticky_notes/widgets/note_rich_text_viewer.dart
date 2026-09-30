import 'package:flutter/material.dart';

import '../models/note_block.dart';
import '../services/note_rich_text_parser.dart';
import 'note_image_block.dart';

/// 便签正文只读视图（spec §3.3）。
///
/// 按正文块顺序渲染：文本块用 `Text.rich` 呈现行内样式
/// （加粗 / 斜体 / 下划线 / 删除线 / 字号 / 颜色），图片块内联展示。
class NoteRichTextViewer extends StatelessWidget {
  const NoteRichTextViewer({super.key, required this.blocks});

  /// 正文块列表。
  final List<NoteBlock> blocks;

  @override
  Widget build(BuildContext context) {
    const parser = NoteRichTextParser();
    final theme = Theme.of(context);
    final visible = parser.visibleBlocks(blocks);

    if (visible.isEmpty) {
      return Text(
        '暂无正文',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in visible)
          if (block is ImageBlock)
            NoteImageBlock(attachment: block.attachment, readOnly: true)
          else
            Text.rich(parser.buildTextSpan(block, block.inlines, theme)),
      ],
    );
  }
}