import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/note_image_attachment.dart';

/// 便签正文图片块。
///
/// 图片作为正文的一个块内联渲染，与文本块上下混排；
/// 点击查看大图（可缩放平移），编辑模式下可删除。
class NoteImageBlock extends StatelessWidget {
  const NoteImageBlock({
    super.key,
    required this.attachment,
    this.onDelete,
    this.readOnly = false,
  });

  /// 图片载荷。
  final NoteImageAttachment attachment;

  /// 删除回调；[readOnly] 为 true 或为 null 时隐藏删除入口。
  final VoidCallback? onDelete;

  /// 只读模式：隐藏删除入口。
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final provider = _provider();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        children: [
          InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: provider == null
                ? null
                : () => _showPreview(context, provider),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // 给定最小高度：图片解码完成前也保持可见区域，避免块高度塌陷。
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 160),
                child: provider == null
                    ? _buildBroken(context)
                    : Image(
                        image: provider,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => _buildBroken(context),
                      ),
              ),
            ),
          ),
          if (!readOnly && onDelete != null)
            Positioned(
              top: 0,
              right: 0,
              child: AdaptiveIconButton(
                icon: const Icon(Icons.cancel, size: 20),
                tooltip: '删除图片',
                onPressed: onDelete,
              ),
            ),
        ],
      ),
    );
  }

  /// 解析 base64 图片；数据损坏时返回 null（由调用方渲染兜底占位）。
  ImageProvider? _provider() {
    try {
      return MemoryImage(base64Decode(attachment.dataBase64));
    } on FormatException {
      return null;
    }
  }

  Widget _buildBroken(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      height: 160,
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        color: colorScheme.onSurfaceVariant,
      ),
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
            // 固定预览视口：避免小图时对话框塌缩为图片原始尺寸。
            SizedBox(
              width: 520,
              height: 400,
              child: InteractiveViewer(
                maxScale: 5,
                child: Image(image: image, fit: BoxFit.contain),
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