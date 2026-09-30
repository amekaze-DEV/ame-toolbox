import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ametoolbox/shared/widgets/adaptive_list_tile.dart';

import '../models/note_category.dart';
import '../models/sticky_note.dart';
import '../services/note_rich_text_parser.dart';
import 'highlighted_text.dart';

/// 便签卡片（列表 / 网格通用，spec §3.2）。
///
/// - 置顶便签前置 `Icons.push_pin`（colorScheme.primary）；
/// - 分类色点 + 正文预览 + 更新时间；
/// - 检索态下按 [titleHighlight] / [bodyHighlight] 高亮命中字符；
/// - 长按 / 右键弹出上下文菜单（编辑、置顶/取消置顶、删除）。
class NoteCardWidget extends StatelessWidget {
  const NoteCardWidget({
    super.key,
    required this.note,
    this.category,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
    this.titleHighlight = const {},
    this.bodyHighlight = const {},
  });

  /// 便签数据。
  final StickyNote note;

  /// 关联分类（可为 null，表示无分类）。
  final NoteCategory? category;

  /// 点击卡片（进入编辑页）。
  final VoidCallback onTap;

  /// 上下文菜单：编辑。
  final VoidCallback onEdit;

  /// 上下文菜单：删除。
  final VoidCallback onDelete;

  /// 上下文菜单：置顶 / 取消置顶。
  final VoidCallback onTogglePin;

  /// 标题命中字符下标（检索态高亮）。
  final Set<int> titleHighlight;

  /// 正文命中字符下标（基于纯文本预览，检索态高亮）。
  final Set<int> bodyHighlight;

  static final _updatedAtFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final preview = const NoteRichTextParser().toPlainText(note.content);
    final category = this.category;
    final metaStyle = textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: AdaptiveListTile(
        leading: category == null
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(category.colorValue),
                  shape: BoxShape.circle,
                ),
              ),
        title: Row(
          children: [
            if (note.isPinned) ...[
              Icon(Icons.push_pin, size: 16, color: colorScheme.primary),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: HighlightedText(
                text: note.title,
                indices: titleHighlight,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (preview.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: HighlightedText(
                  text: preview,
                  indices: bodyHighlight,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      category?.name ?? '无分类',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: metaStyle,
                    ),
                  ),
                  Text(' · ', style: metaStyle),
                  // 窄卡片（横屏双栏）下时间同样需要可收缩，避免元信息行溢出。
                  Flexible(
                    child: Text(
                      _updatedAtFormat.format(note.updatedAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: metaStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: onTap,
        contextMenuBuilder: (context) => <PopupMenuEntry<void>>[
          PopupMenuItem<void>(
            onTap: onEdit,
            child: const Text('编辑'),
          ),
          PopupMenuItem<void>(
            onTap: onTogglePin,
            child: Text(note.isPinned ? '取消置顶' : '置顶'),
          ),
          PopupMenuItem<void>(
            onTap: onDelete,
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
