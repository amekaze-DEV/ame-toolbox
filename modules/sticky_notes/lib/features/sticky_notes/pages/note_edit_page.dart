import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/providers/file_provider.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';
import 'package:ametoolbox/shared/widgets/md3_switch.dart';

import '../models/note_attachment.dart';
import '../models/note_block.dart';
import '../models/note_image_attachment.dart';
import '../models/sticky_note.dart';
import '../providers/attachment_service_provider.dart';
import '../providers/sticky_notes_config_provider.dart';
import '../providers/sticky_notes_provider.dart';
import '../services/attachment_service.dart';
import '../widgets/note_attachment_list.dart';
import '../widgets/note_rich_text_editor.dart';

/// 便签详情 / 新建编辑页（P6）。
///
/// 支持：标题（必填）、博客式富文本正文（段落/标题/列表/待办/引用；
/// 行内加粗/斜体/下划线/删除线/字号/字体颜色；图片内联混排）、
/// 文件附件（添加/打开/下载/删除，单个 ≤ 15MB）、分类选择、置顶开关。
/// 空标题拦截，不允许保存。
class NoteEditPage extends ConsumerStatefulWidget {
  const NoteEditPage({super.key, this.note});

  /// 编辑对象；为 null 表示新建。
  final StickyNote? note;

  @override
  ConsumerState<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends ConsumerState<NoteEditPage> {
  late final TextEditingController _titleController;
  late final AttachmentService _attachmentService;
  late List<NoteBlock> _blocks;
  late List<NoteAttachment> _attachments;

  /// 打开本页时便签已有的附件 id（用于计算新增 / 移除，决定字节清理时机）。
  late final Set<String> _originalAttachmentIds;

  String? _categoryId;
  late bool _isPinned;
  String? _titleError;

  /// 是否已保存成功（未保存离开时清理本次新增的附件字节）。
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _blocks = (note == null || note.content.isEmpty)
        ? <NoteBlock>[const ParagraphBlock(inlines: [])]
        : List<NoteBlock>.of(note.content);
    _attachments = List<NoteAttachment>.of(note?.attachments ?? const []);
    _originalAttachmentIds = {
      for (final attachment in _attachments) attachment.id,
    };
    _categoryId = note?.categoryId;
    _isPinned = note?.isPinned ?? false;
    _attachmentService = ref.read(attachmentServiceProvider);
  }

  @override
  void dispose() {
    _titleController.dispose();
    // 未保存离开：清理本次新增的附件字节，避免留下无人引用的孤儿数据。
    if (!_saved) {
      final kept = {for (final attachment in _attachments) attachment.id};
      for (final id in kept.difference(_originalAttachmentIds)) {
        unawaited(_attachmentService.delete(id));
      }
    }
    super.dispose();
  }

  /// 通过底座文件选择能力挑选图片并转存为 base64 载荷（供正文图片块使用）。
  Future<List<NoteImageAttachment>> _pickImages() async {
    final picked = await ref.read(filePickerProvider).pickImages();
    if (picked.isEmpty) return const [];
    final now = DateTime.now();
    final attachments = <NoteImageAttachment>[];
    for (var i = 0; i < picked.length; i++) {
      final bytes = await picked[i].readContent();
      if (bytes.isEmpty) continue;
      attachments.add(
        NoteImageAttachment(
          id: 'img_${now.microsecondsSinceEpoch}_$i',
          dataBase64: base64Encode(bytes),
          createdAt: now,
        ),
      );
    }
    return attachments;
  }

  /// 从本地选取一个文件作为附件（单个 ≤ 15MB）。
  Future<void> _addAttachment() async {
    final NoteAttachment? attachment;
    try {
      attachment = await _attachmentService.addFromPicker();
    } on AttachmentTooLargeException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('附件超过 15MB 上限，未添加')),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('添加附件失败')),
      );
      return;
    }
    if (attachment == null || !mounted) return;
    setState(() => _attachments = [..._attachments, attachment!]);
  }

  /// 从便签移除附件（确认后仅移出列表，字节在保存时清理）。
  Future<void> _confirmRemoveAttachment(NoteAttachment attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除附件'),
        content: Text('确定删除「${attachment.fileName}」吗？保存后生效。'),
        actions: [
          AdaptiveButton(
            variant: AdaptiveButtonVariant.text,
            label: '取消',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AdaptiveButton(
            variant: AdaptiveButtonVariant.filled,
            label: '删除',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(
      () => _attachments =
          _attachments.where((e) => e.id != attachment.id).toList(),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = '请输入便签标题');
      return;
    }

    final now = DateTime.now();
    final existing = widget.note;
    final content = _blocks.isEmpty
        ? <NoteBlock>[const ParagraphBlock(inlines: [])]
        : _blocks;

    final StickyNote note;
    if (existing == null) {
      note = StickyNote(
        id: 'note_${now.microsecondsSinceEpoch}',
        title: title,
        content: content,
        attachments: _attachments,
        categoryId: _categoryId,
        isPinned: _isPinned,
        pinnedAt: _isPinned ? now : null,
        createdAt: now,
        updatedAt: now,
      );
    } else {
      final pinnedChanged = _isPinned != existing.isPinned;
      note = existing.copyWith(
        title: title,
        content: content,
        attachments: _attachments,
        categoryId: _categoryId,
        clearCategoryId: _categoryId == null,
        isPinned: _isPinned,
        pinnedAt: (pinnedChanged && _isPinned) ? now : null,
        clearPinnedAt: pinnedChanged && !_isPinned,
        updatedAt: now,
      );
    }

    final controller = ref.read(stickyNotesProvider);
    if (existing == null) {
      await controller.add(note);
    } else {
      await controller.update(note);
    }
    _saved = true;

    // 保存成功后清理被移除附件的字节（不再被该便签引用）。
    final kept = {for (final attachment in _attachments) attachment.id};
    for (final id in _originalAttachmentIds.difference(kept)) {
      await _attachmentService.delete(id);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// 删除当前便签（仅编辑已有便签时可用）：确认后删除并返回便签列表。
  Future<void> _confirmDelete() async {
    final note = widget.note;
    if (note == null) return;

    final editedTitle = _titleController.text.trim();
    final displayTitle = editedTitle.isEmpty ? note.title : editedTitle;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除便签'),
        content: Text('确定删除"$displayTitle"吗？'),
        actions: [
          AdaptiveButton(
            variant: AdaptiveButtonVariant.text,
            label: '取消',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AdaptiveButton(
            variant: AdaptiveButtonVariant.filled,
            label: '删除',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // 附件字节由控制器在删除便签时级联清理。
    _saved = true;
    await ref.read(stickyNotesProvider).delete(note.id);
    if (!mounted) return;
    // 返回便签列表，避免停留在已删除便签的查看页。
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categories = ref.watch(stickyNotesConfigProvider).config.categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? '新建便签' : '编辑便签'),
        actions: [
          // 仅编辑已有便签时提供删除入口（新建态隐藏）。
          if (widget.note != null)
            AdaptiveIconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除便签',
              onPressed: _confirmDelete,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AdaptiveButton(
              variant: AdaptiveButtonVariant.filled,
              label: '保存',
              onPressed: _save,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '标题',
              hintText: '便签标题',
              errorText: _titleError,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
          ),
          const SizedBox(height: 16),
          NoteRichTextEditor(
            blocks: _blocks,
            onChanged: (blocks) => setState(() => _blocks = blocks),
            onPickImages: _pickImages,
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(child: Text('附件', style: textTheme.titleSmall)),
              AdaptiveButton(
                variant: AdaptiveButtonVariant.outlined,
                icon: Icons.attach_file,
                label: '添加附件',
                onPressed: _addAttachment,
              ),
            ],
          ),
          if (_attachments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '暂无附件，单个文件不超过 15MB',
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            NoteAttachmentList(
              attachments: _attachments,
              onDelete: _confirmRemoveAttachment,
            ),
          const Divider(height: 32),
          Text('分类', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownMenu<String>(
            width: 260,
            initialSelection: _categoryId ?? '',
            label: const Text('选择分类（可选）'),
            dropdownMenuEntries: [
              const DropdownMenuEntry<String>(value: '', label: '无分类'),
              for (final category in categories)
                DropdownMenuEntry<String>(
                  value: category.id,
                  label: category.name,
                ),
            ],
            onSelected: (value) => setState(
              () => _categoryId =
                  (value == null || value.isEmpty) ? null : value,
            ),
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(child: Text('置顶', style: textTheme.titleSmall)),
              Md3Switch(
                value: _isPinned,
                onChanged: (value) => setState(() => _isPinned = value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}