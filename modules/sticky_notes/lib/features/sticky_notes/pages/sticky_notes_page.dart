import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/layout/responsive_builder.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/note_category.dart';
import '../models/sticky_note.dart';
import '../providers/note_query_service_provider.dart';
import '../providers/sticky_notes_config_provider.dart';
import '../providers/sticky_notes_provider.dart';
import '../widgets/note_card_widget.dart';
import '../widgets/note_category_filter.dart';
import '../widgets/note_empty_view.dart';
import 'note_edit_page.dart';

/// 便签主页面（spec §3.2）。
///
/// - 顶部分类筛选条；竖屏单列列表、横屏两列网格（高度可变，按行对齐）；
/// - 置顶便签恒排在普通便签之前（由 [NoteQueryService] 保证）；
/// - 点击卡片进入编辑页；长按 / 右键弹出上下文菜单（编辑、置顶/取消置顶、删除）。
class StickyNotesPage extends ConsumerWidget {
  const StickyNotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(stickyNotesProvider);
    final config = ref.watch(stickyNotesConfigProvider).config;
    final query = ref.watch(noteQueryServiceProvider);

    final visible = query.query(
      controller.notes,
      mode: config.defaultSortMode,
      categoryId: controller.categoryFilter,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('便签'),
        actions: [
          AdaptiveIconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建便签',
            onPressed: () => _openEditor(context, null),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ResponsiveBuilder(
        portraitBuilder: (context) => _buildBody(
          context,
          ref,
          notes: visible,
          categories: config.categories,
          filter: controller.categoryFilter,
          twoColumn: false,
        ),
        landscapeBuilder: (context) => _buildBody(
          context,
          ref,
          notes: visible,
          categories: config.categories,
          filter: controller.categoryFilter,
          twoColumn: true,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref, {
    required List<StickyNote> notes,
    required List<NoteCategory> categories,
    required String? filter,
    required bool twoColumn,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NoteCategoryFilter(
          categories: categories,
          selectedId: filter,
          onSelected: (id) =>
              ref.read(stickyNotesProvider).setCategoryFilter(id),
        ),
        Expanded(
          child: notes.isEmpty
              ? NoteEmptyView(
                  message: filter == null ? '暂无便签' : '该分类下暂无便签',
                )
              : twoColumn
                  ? _buildTwoColumnList(context, ref, notes, categories)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: notes.length,
                      itemBuilder: (context, index) =>
                          _buildCard(context, ref, notes[index], categories),
                    ),
        ),
      ],
    );
  }

  /// 横屏两列网格：按行分块，行内两张卡片高度可变（取较高者）。
  Widget _buildTwoColumnList(
    BuildContext context,
    WidgetRef ref,
    List<StickyNote> notes,
    List<NoteCategory> categories,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      itemCount: (notes.length + 1) ~/ 2,
      itemBuilder: (context, rowIndex) {
        final left = notes[rowIndex * 2];
        final rightIndex = rowIndex * 2 + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCard(context, ref, left, categories)),
              SizedBox(width: 8),
              Expanded(
                child: rightIndex < notes.length
                    ? _buildCard(context, ref, notes[rightIndex], categories)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    StickyNote note,
    List<NoteCategory> categories,
  ) {
    return NoteCardWidget(
      note: note,
      category: _categoryById(categories, note.categoryId),
      onTap: () => _openEditor(context, note),
      onEdit: () => _openEditor(context, note),
      onDelete: () => _confirmDelete(context, ref, note),
      onTogglePin: () => ref.read(stickyNotesProvider).togglePin(note.id),
    );
  }

  static NoteCategory? _categoryById(
    List<NoteCategory> categories,
    String? id,
  ) {
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  void _openEditor(BuildContext context, StickyNote? note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => NoteEditPage(note: note)),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, StickyNote note) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除便签'),
        content: Text('确定删除"${note.title}"吗？'),
        actions: [
          AdaptiveButton(
            variant: AdaptiveButtonVariant.text,
            label: '取消',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          AdaptiveButton(
            variant: AdaptiveButtonVariant.filled,
            label: '删除',
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(stickyNotesProvider).delete(note.id);
            },
          ),
        ],
      ),
    );
  }
}
