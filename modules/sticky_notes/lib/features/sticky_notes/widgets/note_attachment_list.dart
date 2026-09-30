import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';
import 'package:ametoolbox/shared/widgets/adaptive_list_tile.dart';

import '../models/note_attachment.dart';
import '../providers/attachment_service_provider.dart';

/// 人类可读的文件大小文案（B / KB / MB，至多一位小数）。
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${_trimZero(kb)} KB';
  return '${_trimZero(kb / 1024)} MB';
}

String _trimZero(double value) {
  final text = value.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

/// 便签附件列表（查看页只读、编辑页可删）。
///
/// 每行展示文件名与大小，并提供「打开」（系统默认查看器）/「下载」（另存为）
/// 操作；[onDelete] 非空时额外展示「删除」入口（删除时机由调用方决定）。
class NoteAttachmentList extends ConsumerWidget {
  const NoteAttachmentList({
    super.key,
    required this.attachments,
    this.onDelete,
  });

  /// 附件元数据列表（按便签内顺序展示）。
  final List<NoteAttachment> attachments;

  /// 删除回调；为 null 表示只读（不展示删除按钮）。
  final ValueChanged<NoteAttachment>? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final attachment in attachments)
          AdaptiveListTile(
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(
              attachment.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(formatFileSize(attachment.sizeBytes)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdaptiveIconButton(
                  icon: const Icon(Icons.open_in_new),
                  tooltip: '打开附件',
                  onPressed: () => _open(context, ref, attachment),
                ),
                AdaptiveIconButton(
                  icon: const Icon(Icons.download_outlined),
                  tooltip: '下载附件',
                  onPressed: () => _download(context, ref, attachment),
                ),
                if (onDelete != null)
                  AdaptiveIconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: '删除附件',
                    onPressed: () => onDelete!(attachment),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// 用系统默认查看器打开附件；失败时提示。
  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    NoteAttachment attachment,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(attachmentServiceProvider).open(attachment);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('打开「${attachment.fileName}」失败')),
      );
    }
  }

  /// 弹出另存为对话框下载附件；取消不提示，失败时提示。
  Future<void> _download(
    BuildContext context,
    WidgetRef ref,
    NoteAttachment attachment,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await ref.read(attachmentServiceProvider).download(attachment);
      if (path == null) return;
      messenger.showSnackBar(
        SnackBar(content: Text('已保存到 $path')),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('下载「${attachment.fileName}」失败')),
      );
    }
  }
}