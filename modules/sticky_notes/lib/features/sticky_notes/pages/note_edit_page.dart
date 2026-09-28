import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/providers/file_provider.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';
import 'package:ametoolbox/shared/widgets/md3_switch.dart';

import '../models/note_block.dart';
import '../models/note_image_attachment.dart';
import '../models/sticky_note.dart';
import '../providers/sticky_notes_config_provider.dart';
import '../providers/sticky_notes_provider.dart';
import '../widgets/note_rich_text_editor.dart';

/// 便签详情 / 新建编辑页（P6）。
///
/// 支持：标题（必填）、博客式富文本正文（段落/标题/列表/待办/引用；
/// 行内加粗/斜体/下划线/删除线/字号/字体颜色；图片内联混排）、
/// 分类选择、置顶开关。空标题拦截，不允许保存。
class NoteEditPage extends ConsumerStatefulWidget {
  const NoteEditPage({super.key, this.note});

  /// 编辑对象；为 null 表示新建。
  final StickyNote? note;

  @override
  ConsumerState<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends ConsumerState<NoteEditPage> {
  late final TextEditingController _titleController;
  late List<NoteBlock> _blocks;
  String? _categoryId;
  late bool _isPinned;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _blocks = (note == null || note.content.isEmpty)
        ? <NoteBlock>[const ParagraphBlock(inlines: [])]
        : List<NoteBlock>.of(note.content);
    _categoryId = note?.categoryId;
    _isPinned = note?.isPinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
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
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categories = ref.watch(stickyNotesConfigProvider).config.categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? '新建便签' : '编辑便签'),
        actions: [
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