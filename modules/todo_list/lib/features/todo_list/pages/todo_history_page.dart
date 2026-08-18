import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/todo_category.dart';
import '../models/todo_item.dart';
import '../models/todo_priority.dart';
import '../providers/todo_config_provider.dart';
import '../providers/todo_list_provider.dart';
import '../widgets/todo_empty_view.dart';
import '../widgets/todo_item_tile.dart' show todoPriorityColor;
import '../widgets/todo_list_filter.dart';
import 'todo_detail_page.dart';
import 'todo_detail_view_page.dart';

/// 分类筛选（空集合表示不限）。
final _historyCategoryFilterProvider = StateProvider<Set<String>>((ref) => const {});

/// 优先级筛选（空集合表示不限）。
final _historyPriorityFilterProvider =
    StateProvider<Set<TodoPriority>>((ref) => const {});

/// 待办历史页：记录已关闭的待办事项。
///
/// 仅记录「事项本身已结束」的条目：一次性事项完成、循环事项整系列关闭；
/// 循环事项仅单日完成（仍在循环）的实例不记录。
/// 提供引用功能：引用历史事项创建新事项（不保留期限与循环规则）。
class TodoHistoryPage extends ConsumerWidget {
  const TodoHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(todoListProvider);
    final config = ref.watch(todoConfigProvider);
    final categoryFilter = ref.watch(_historyCategoryFilterProvider);
    final priorityFilter = ref.watch(_historyPriorityFilterProvider);

    final history = list.historyItems;
    final filtered = applyTodoFilters(history, categoryFilter, priorityFilter);

    final colorScheme = Theme.of(context).colorScheme;
    final activeFilters = buildFilterEntries(
      categoryFilter,
      priorityFilter,
      config.config.categories,
      colorScheme,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('待办历史'),
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
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (activeFilters.isNotEmpty)
            TodoFilterStatusBar(
              activeFilters: activeFilters,
              onRemoveFilter: (key) => _removeFilter(ref, key),
              onClearFilters: () => _clearFilters(ref),
            ),
          Expanded(
            child: filtered.isEmpty
                ? TodoEmptyView(
                    message: activeFilters.isNotEmpty
                        ? '筛选无匹配结果'
                        : '暂无已关闭的待办事项',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final category = _categoryById(
                        config.config.categories,
                        item.categoryId,
                      );
                      return ListTile(
                        key: ValueKey('history_${item.id}'),
                        leading: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: todoPriorityColor(item.priority, colorScheme),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(item.title),
                        subtitle: Text(
                          [
                            item.isRecurring ? '循环' : '一次性',
                            if (category != null) category.name,
                            if (item.completedAt != null)
                              _fmtDate(item.completedAt!),
                          ].join(' · '),
                        ),
                        onTap: () => _openView(context, item),
                        trailing: AdaptiveButton(
                          variant: AdaptiveButtonVariant.outlined,
                          icon: Icons.add_link_outlined,
                          label: '引用',
                          onPressed: () => _openQuote(context, item),
                        ),
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
        initialCategories: ref.read(_historyCategoryFilterProvider),
        initialPriorities: ref.read(_historyPriorityFilterProvider),
      ),
    );
    if (result == null) return;
    ref.read(_historyCategoryFilterProvider.notifier).state = result.categories;
    ref.read(_historyPriorityFilterProvider.notifier).state = result.priorities;
  }

  void _removeFilter(WidgetRef ref, String key) {
    if (key == 'cat_none') {
      final next = Set<String>.of(ref.read(_historyCategoryFilterProvider))
        ..remove(todoNoCategoryKey);
      ref.read(_historyCategoryFilterProvider.notifier).state = next;
    } else if (key.startsWith('cat_')) {
      final next = Set<String>.of(ref.read(_historyCategoryFilterProvider))
        ..remove(key.substring(4));
      ref.read(_historyCategoryFilterProvider.notifier).state = next;
    } else if (key.startsWith('pri_')) {
      final p = TodoPriority.values.firstWhere(
        (e) => e.name == key.substring(4),
      );
      final next = Set<TodoPriority>.of(ref.read(_historyPriorityFilterProvider))
        ..remove(p);
      ref.read(_historyPriorityFilterProvider.notifier).state = next;
    }
  }

  void _clearFilters(WidgetRef ref) {
    ref.read(_historyCategoryFilterProvider.notifier).state = const {};
    ref.read(_historyPriorityFilterProvider.notifier).state = const {};
  }

  void _openView(BuildContext context, TodoItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TodoDetailViewPage(item: item, hideEdit: true),
      ),
    );
  }

  /// 引用历史事项创建新事项（预填字段，不保留期限与循环规则）。
  void _openQuote(BuildContext context, TodoItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TodoDetailPage(prefill: item),
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

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
