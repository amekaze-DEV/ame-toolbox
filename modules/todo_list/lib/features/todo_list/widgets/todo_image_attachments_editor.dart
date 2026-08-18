import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/todo_image_attachment.dart';

/// 待办详情图片附件编辑器。
///
/// - 缩略图列表展示，点击查看大图（可缩放平移）。
/// - 可编辑模式下每张图片可删除、可通过 [onAdd] 添加（调试期由页面注入）；
///   [readOnly] 为 true 时仅展示（查看子页面）。
class TodoImageAttachmentsEditor extends StatelessWidget {
  const TodoImageAttachmentsEditor({
    super.key,
    required this.images,
    required this.onChanged,
    this.onAdd,
    this.readOnly = false,
  });

  /// 当前图片附件列表。
  final List<TodoImageAttachment> images;

  /// 附件列表变更回调（删除后）。
  final ValueChanged<List<TodoImageAttachment>> onChanged;

  /// 添加图片回调；为 null 时隐藏添加按钮。
  final VoidCallback? onAdd;

  /// 只读模式：隐藏删除与添加入口（用于查看子页面）。
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('图片附件', style: textTheme.titleSmall),
        const SizedBox(height: 8),
        if (images.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '暂无图片',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final attachment in images)
                _buildThumbnail(context, attachment),
            ],
          ),
        if (!readOnly && onAdd != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: AdaptiveButton(
              variant: AdaptiveButtonVariant.outlined,
              icon: Icons.add_photo_alternate_outlined,
              label: '添加图片',
              onPressed: onAdd,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildThumbnail(BuildContext context, TodoImageAttachment attachment) {
    final colorScheme = Theme.of(context).colorScheme;
    final image = MemoryImage(base64Decode(attachment.dataBase64));

    return Stack(
      children: [
        InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () => _showPreview(context, image),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image(
              image: image,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 96,
                height: 96,
                color: colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        if (!readOnly)
          Positioned(
            top: 0,
            right: 0,
            child: AdaptiveIconButton(
              icon: const Icon(Icons.cancel, size: 20),
              tooltip: '删除图片',
              onPressed: () => onChanged(
                images.where((e) => e.id != attachment.id).toList(),
              ),
            ),
          ),
      ],
    );
  }

  void _showPreview(BuildContext context, ImageProvider image) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
              child: InteractiveViewer(
                maxScale: 5,
                child: Image(image: image),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: AdaptiveIconButton(
                icon: const Icon(Icons.close),
                tooltip: '关闭',
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}