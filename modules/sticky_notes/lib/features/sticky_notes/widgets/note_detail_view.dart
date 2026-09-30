import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/note_category.dart';
import '../models/sticky_note.dart';
import 'note_attachment_list.dart';
import 'note_rich_text_viewer.dart';

/// 便签内容只读展示（查看页与横屏预览共用，spec §3.3）。
///
/// 展示标题、分类 / 时间元信息、正文（含内联图片）与文件附件
/// （附件仅提供打开 / 下载），不含任何编辑入口。
class NoteDetailView extends StatelessWidget {
  const NoteDetailView({super.key, required this.note, this.category});

  /// 便签数据。
  final StickyNote note;

  /// 关联分类（可为 null，表示无分类）。
  final NoteCategory? category;

  static final _updatedAtFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final metaStyle = textTheme.labelMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (note.isPinned) ...[
                Icon(Icons.push_pin, size: 18, color: colorScheme.primary),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(note.title, style: textTheme.headlineSmall),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (category != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(category!.colorValue),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  category?.name ?? '无分类',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metaStyle,
                ),
              ),
              Text(' · ', style: metaStyle),
              Text(_updatedAtFormat.format(note.updatedAt), style: metaStyle),
            ],
          ),
          const Divider(height: 24),
          NoteRichTextViewer(blocks: note.content),
          if (note.attachments.isNotEmpty) ...[
            const Divider(height: 32),
            Text('附件', style: textTheme.titleSmall),
            NoteAttachmentList(attachments: note.attachments),
          ],
        ],
      ),
    );
  }
}