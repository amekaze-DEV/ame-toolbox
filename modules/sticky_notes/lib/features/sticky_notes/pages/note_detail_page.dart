import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/note_category.dart';
import '../models/sticky_note.dart';
import '../providers/sticky_notes_config_provider.dart';
import '../providers/sticky_notes_provider.dart';
import '../widgets/note_detail_view.dart';
import 'note_edit_page.dart';

/// 便签查看页（spec §3.3）。
///
/// 只读展示便签内容，编辑入口位于顶栏；编辑返回后内容即时刷新。
/// 便签被删除时展示占位提示。
class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.noteId});

  /// 便签 id（按 id 取最新数据，保证编辑后内容刷新）。
  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(stickyNotesProvider).notes;
    final categories = ref.watch(stickyNotesConfigProvider).config.categories;
    final note = findNoteById(notes, noteId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('便签详情'),
        actions: [
          if (note != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AdaptiveButton(
                variant: AdaptiveButtonVariant.filled,
                icon: Icons.edit_outlined,
                label: '编辑',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NoteEditPage(note: note),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: note == null
          ? const Center(child: Text('该便签已被删除'))
          : NoteDetailView(
              note: note,
              category: findCategoryById(categories, note.categoryId),
            ),
    );
  }
}

/// 按 id 查找便签（未找到返回 null）。
StickyNote? findNoteById(List<StickyNote> notes, String id) {
  for (final note in notes) {
    if (note.id == id) return note;
  }
  return null;
}

/// 按 id 查找分类（id 为 null 或未找到返回 null）。
NoteCategory? findCategoryById(List<NoteCategory> categories, String? id) {
  if (id == null) return null;
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return null;
}