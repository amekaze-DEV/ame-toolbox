import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/todo_category.dart';
import '../models/todo_item.dart';
import '../models/todo_priority.dart';
import '../providers/todo_config_provider.dart';
import '../providers/todo_list_provider.dart';
import '../providers/todo_query_service_provider.dart';
import '../widgets/todo_empty_view.dart';
import '../widgets/todo_item_tile.dart';
import '../widgets/todo_list_filter.dart';
import 'todo_detail_page.dart';
import 'todo_detail_view_page.dart';
import 'todo_history_page.dart';

/// 分类筛选（空集合表示不限）。
final _summaryCategoryFilterProvider = StateProvider<Set<String>>((ref) => const {});

/// 优先级筛选（空集合表示不限）。
final _summaryPriorityFilterProvider =
    StateProvider<Set<TodoPriority>>((ref) => const {});

/// 待办汇总页：显示所有在运转的待办事项（未归档）。
///
/// 包括一次性事项和循环模板，点击进入对应事项的设置页。
/// 筛选功能参考主页待办清单。
class TodoSummaryPage extends ConsumerWidget {
  const TodoSummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(todoListProvider);
    final query = ref.watch(todoQueryServiceProvider);
    final config = ref.watch(todoConfigProvider);
    final categoryFilter = ref.watch(_summaryCategoryFilterProvider);
    final priorityFilter = ref.watch(_summaryPriorityFilterProvider);

    // 在运转的待办：未归档的项（一次性事项 + 循环模板，排除每日实例）
    final active = list.activeItems;
    final filtered = applyTodoFilters(active, categoryFilter, priorityFilter);
    final sorted = query.sortByPriority(
      filtered,
      dailyTop: config.config.dailyTop,
    );

    final colorScheme = Theme.of(context).colorScheme;
    final activeFilters = buildFilterEntries(
      categoryFilter,
      priorityFilter,
      config.config.categories,
      colorScheme,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('待办汇总'),
        actions: [
          AdaptiveIconButton(
            icon: Icon(
              activeFilters.isNotEmpty
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            tooltip: '筛选',
            onPressed: () => _openFilter(context, ref),
          ),
          AdaptiveButton(
            variant: AdaptiveButtonVariant.text,
            icon: Icons.history_outlined,
            label: '待办历史',
            onPressed: () => _openHistory(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 筛选状态条
          if (activeFilters.isNotEmpty)
            TodoFilterStatusBar(
              activeFilters: activeFilters,
              onRemoveFilter: (key) => _removeFilter(ref, key),
              onClearFilters: () => _clearFilters(ref),
            ),
          Expanded(
            child: sorted.isEmpty
                ? TodoEmptyView(
                    message: activeFilters.isNotEmpty
                        ? '筛选无匹配结果'
                        : '暂无在运转的待办事项',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final item = sorted[index];
                      final category = _categoryById(
                        config.config.categories,
                        item.categoryId,
                      );
                      return TodoItemTile(
                        item: item,
                        isOverdue: false,
                        showCheckButton: false,
                        categoryName: category?.name,
                        categoryColor: category == null
                            ? null
                            : Color(category.colorValue),
                        onTap: () => _openDetail(context, ref, item),
                        onToggleComplete: () =>
                            ref.read(todoListProvider).toggleComplete(item.id),
                        onEdit: () => _openEdit(context, ref, item),
                        onDelete: () => _confirmDelete(context, ref, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openFilter(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<TodoFilterSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TodoFilterSheet(
        initialCategories: ref.read(_summaryCategoryFilterProvider),
        initialPriorities: ref.read(_summaryPriorityFilterProvider),
      ),
    );
    if (result == null) return;
    ref.read(_summaryCategoryFilterProvider.notifier).state = result.categories;
    ref.read(_summaryPriorityFilterProvider.notifier).state = result.priorities;
  }

  void _removeFilter(WidgetRef ref, String key) {
    if (key == 'cat_none') {
      final next = Set<String>.of(ref.read(_summaryCategoryFilterProvider))
        ..remove(todoNoCategoryKey);
      ref.read(_summaryCategoryFilterProvider.notifier).state = next;
    } else if (key.startsWith('cat_')) {
      final next = Set<String>.of(ref.read(_summaryCategoryFilterProvider))
        ..remove(key.substring(4));
      ref.read(_summaryCategoryFilterProvider.notifier).state = next;
    } else if (key.startsWith('pri_')) {
      final p = TodoPriority.values.firstWhere(
        (e) => e.name == key.substring(4),
      );
      final next = Set<TodoPriority>.of(ref.read(_summaryPriorityFilterProvider))
        ..remove(p);
      ref.read(_summaryPriorityFilterProvider.notifier).state = next;
    }
  }

  void _clearFilters(WidgetRef ref) {
    ref.read(_summaryCategoryFilterProvider.notifier).state = const {};
    ref.read(_summaryPriorityFilterProvider.notifier).state = const {};
  }

  void _openDetail(BuildContext context, WidgetRef ref, TodoItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TodoDetailViewPage(item: item),
      ),
    );
  }

  void _openEdit(BuildContext context, WidgetRef ref, TodoItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TodoDetailPage(item: item),
      ),
    );
  }

  void _openHistory(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TodoHistoryPage(),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TodoItem item,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除待办'),
        content: Text('确定删除"${item.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(todoListProvider).delete(item.id);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  static TodoCategory? _categoryById(
    List<TodoCategory> categories,
    String? id,
  ) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }
}