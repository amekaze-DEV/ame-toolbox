import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/layout/responsive_builder.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/note_category.dart';
import '../models/sticky_note.dart';
import '../providers/note_query_service_provider.dart';
import '../services/note_search_service.dart';
import '../providers/sticky_notes_config_provider.dart';
import '../providers/sticky_notes_provider.dart';
import '../widgets/note_card_widget.dart';
import '../widgets/note_category_filter.dart';
import '../widgets/note_detail_view.dart';
import '../widgets/note_empty_view.dart';
import 'note_detail_page.dart';
import 'note_edit_page.dart';

/// 便签主页面（spec §3.2）。
///
/// - 顶部分类筛选条；
/// - 顶栏搜索按钮：展开为关键字输入框，对标题与正文做模糊检索（spec §3.6），
///   命中字符高亮，与分类筛选叠加生效；
/// - 竖屏：单列卡片列表，点击卡片进入**查看页**（编辑入口在查看页）；
/// - 横屏：左侧便签列表（单列）、右侧内容预览区，可直接查看所选便签并提供
///   编辑入口（列表旁查看内容，无需跳页）；
/// - 长按 / 右键弹出上下文菜单（编辑、置顶/取消置顶、删除）。
class StickyNotesPage extends ConsumerStatefulWidget {
  const StickyNotesPage({super.key});

  @override
  ConsumerState<StickyNotesPage> createState() => _StickyNotesPageState();
}

class _StickyNotesPageState extends ConsumerState<StickyNotesPage> {
  /// 横屏预览区当前选中的便签 id。
  String? _selectedNoteId;

  /// 是否处于检索态（顶栏展开为搜索输入框）。
  bool _searching = false;

  /// 当前关键字（输入即时生效）。
  String _keyword = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 切换检索态；退出检索时清空关键字并恢复完整列表。
  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      _keyword = '';
      _searchController.clear();
    });
  }

  /// 清空关键字（保留检索态）。
  void _clearKeyword() {
    setState(() {
      _keyword = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(stickyNotesProvider);
    final config = ref.watch(stickyNotesConfigProvider).config;
    final query = ref.watch(noteQueryServiceProvider);

    final keyword = _keyword.trim();
    final searching = keyword.isNotEmpty;
    // 检索态命中结果（含高亮下标）；非检索态回退为常规筛选 + 排序。
    final hits = searching
        ? query.search(
            controller.notes,
            mode: config.defaultSortMode,
            categoryId: controller.categoryFilter,
            keyword: keyword,
          )
        : const <NoteSearchHit>[];
    final visible = searching
        ? [for (final hit in hits) hit.note]
        : query.query(
            controller.notes,
            mode: config.defaultSortMode,
            categoryId: controller.categoryFilter,
          );
    final highlights = {for (final hit in hits) hit.note.id: hit};
    final emptyMessage = switch ((searching, controller.categoryFilter)) {
      (true, _) => '未找到匹配的便签',
      (false, null) => '暂无便签',
      (false, _) => '该分类下暂无便签',
    };

    return Scaffold(
      appBar: _buildAppBar(),
      body: ResponsiveBuilder(
        portraitBuilder: (context) => _buildListPane(
          notes: visible,
          categories: config.categories,
          filter: controller.categoryFilter,
          highlights: highlights,
          emptyMessage: emptyMessage,
          onTapNote: (note) => _openDetail(note),
        ),
        landscapeBuilder: (context) => _buildMasterDetail(
          notes: visible,
          categories: config.categories,
          filter: controller.categoryFilter,
          highlights: highlights,
          emptyMessage: emptyMessage,
        ),
      ),
    );
  }

  /// 顶栏：常规态展示标题与操作入口；检索态切换为搜索输入框。
  PreferredSizeWidget _buildAppBar() {
    if (!_searching) {
      return AppBar(
        title: const Text('便签'),
        actions: [
          AdaptiveIconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索便签',
            onPressed: _toggleSearch,
          ),
          AdaptiveIconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建便签',
            onPressed: () => _openEditor(null),
          ),
          const SizedBox(width: 4),
        ],
      );
    }

    return AppBar(
      leading: AdaptiveIconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: '退出搜索',
        onPressed: _toggleSearch,
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '搜索标题或正文',
          border: InputBorder.none,
        ),
        onChanged: (value) => setState(() => _keyword = value),
      ),
      actions: [
        if (_keyword.isNotEmpty)
          AdaptiveIconButton(
            icon: const Icon(Icons.clear),
            tooltip: '清空关键字',
            onPressed: _clearKeyword,
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  /// 横屏：列表 + 预览双栏（预览区直接查看内容并提供编辑入口）。
  Widget _buildMasterDetail({
    required List<StickyNote> notes,
    required List<NoteCategory> categories,
    required String? filter,
    required Map<String, NoteSearchHit> highlights,
    required String emptyMessage,
  }) {
    final selected = _selectedNote(notes);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: _buildListPane(
            notes: notes,
            categories: categories,
            filter: filter,
            highlights: highlights,
            emptyMessage: emptyMessage,
            onTapNote: (note) => setState(() => _selectedNoteId = note.id),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: selected == null
              ? NoteEmptyView(
                  message: notes.isEmpty ? '暂无可查看的便签' : '请选择便签查看内容',
                )
              : _buildPreviewPane(selected, categories),
        ),
      ],
    );
  }

  /// 预览区：内容只读展示 + 顶部编辑入口。
  Widget _buildPreviewPane(
    StickyNote note,
    List<NoteCategory> categories,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Expanded(child: Text('内容查看', style: textTheme.titleSmall)),
              AdaptiveButton(
                variant: AdaptiveButtonVariant.text,
                icon: Icons.edit_outlined,
                label: '编辑',
                onPressed: () => _openEditor(note),
              ),
            ],
          ),
        ),
        Expanded(
          child: NoteDetailView(
            note: note,
            category: findCategoryById(categories, note.categoryId),
          ),
        ),
      ],
    );
  }

  /// 预览区应展示的便签：优先选中项，否则回退到列表首项。
  StickyNote? _selectedNote(List<StickyNote> notes) {
    if (notes.isEmpty) return null;
    final selected = _selectedNoteId;
    if (selected != null) {
      final match = findNoteById(notes, selected);
      if (match != null) return match;
    }
    return notes.first;
  }

  /// 分类筛选条 + 便签卡片列表（竖屏单列）。
  Widget _buildListPane({
    required List<StickyNote> notes,
    required List<NoteCategory> categories,
    required String? filter,
    required Map<String, NoteSearchHit> highlights,
    required String emptyMessage,
    required ValueChanged<StickyNote> onTapNote,
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
              ? NoteEmptyView(message: emptyMessage)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: notes.length,
                  itemBuilder: (context, index) => _buildCard(
                    notes[index],
                    categories,
                    highlights,
                    onTapNote,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCard(
    StickyNote note,
    List<NoteCategory> categories,
    Map<String, NoteSearchHit> highlights,
    ValueChanged<StickyNote> onTapNote,
  ) {
    final hit = highlights[note.id];
    return NoteCardWidget(
      note: note,
      category: findCategoryById(categories, note.categoryId),
      titleHighlight: hit?.titleHighlight ?? const {},
      bodyHighlight: hit?.bodyHighlight ?? const {},
      onTap: () => onTapNote(note),
      onEdit: () => _openEditor(note),
      onDelete: () => _confirmDelete(note),
      onTogglePin: () => ref.read(stickyNotesProvider).togglePin(note.id),
    );
  }

  /// 进入查看页（编辑入口在查看页内）。
  void _openDetail(StickyNote note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => NoteDetailPage(noteId: note.id)),
    );
  }

  /// 进入编辑页（新建时 [note] 为 null）。
  void _openEditor(StickyNote? note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => NoteEditPage(note: note)),
    );
  }

  void _confirmDelete(StickyNote note) {
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