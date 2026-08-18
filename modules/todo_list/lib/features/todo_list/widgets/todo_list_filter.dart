import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/todo_category.dart';
import '../models/todo_item.dart';
import '../models/todo_priority.dart';
import '../providers/todo_config_provider.dart';
import '../widgets/todo_item_tile.dart' show todoPriorityColor;

/// 分类筛选中「无分类」的哨兵值。
const todoNoCategoryKey = '__no_category__';

/// 筛选结果返回体：分类集合 + 优先级集合。
typedef TodoFilterSelection = ({
  Set<String> categories,
  Set<TodoPriority> priorities,
});

/// 按分类 / 优先级复选过滤（空集合表示不限）。
List<TodoItem> applyTodoFilters(
  List<TodoItem> items,
  Set<String> categoryFilter,
  Set<TodoPriority> priorityFilter,
) {
  return items.where((item) {
    if (categoryFilter.isNotEmpty) {
      final hit = item.categoryId == null
          ? categoryFilter.contains(todoNoCategoryKey)
          : categoryFilter.contains(item.categoryId);
      if (!hit) return false;
    }
    if (priorityFilter.isNotEmpty) {
      if (!priorityFilter.contains(item.priority)) return false;
    }
    return true;
  }).toList();
}

/// 筛选状态条条目。
typedef TodoFilterEntry = ({String key, String label, Color? color});

/// 将当前筛选状态展开为展示条目（含 key、名称、颜色）。
List<TodoFilterEntry> buildFilterEntries(
  Set<String> categoryFilter,
  Set<TodoPriority> priorityFilter,
  List<TodoCategory> categories,
  ColorScheme colorScheme,
) {
  final entries = <TodoFilterEntry>[];
  for (final id in categoryFilter) {
    if (id == todoNoCategoryKey) {
      entries.add((key: 'cat_none', label: '无分类', color: null));
    } else {
      final c = _categoryById(categories, id);
      entries.add((
        key: 'cat_$id',
        label: c?.name ?? id,
        color: c == null ? null : Color(c.colorValue),
      ));
    }
  }
  for (final p in priorityFilter) {
    entries.add((
      key: 'pri_${p.name}',
      label: p.displayName,
      color: todoPriorityColor(p, colorScheme),
    ));
  }
  return entries;
}

TodoCategory? _categoryById(List<TodoCategory> categories, String? id) {
  if (id == null) return null;
  for (final c in categories) {
    if (c.id == id) return c;
  }
  return null;
}

/// 分类 / 优先级复选筛选面板（紧凑 BottomSheet，受控组件）。
///
/// 初始值由 [initialCategories] / [initialPriorities] 传入，确定后以
/// [TodoFilterSelection] 形式返回，由调用方决定如何落地。
class TodoFilterSheet extends ConsumerStatefulWidget {
  const TodoFilterSheet({
    super.key,
    required this.initialCategories,
    required this.initialPriorities,
  });

  final Set<String> initialCategories;
  final Set<TodoPriority> initialPriorities;

  @override
  ConsumerState<TodoFilterSheet> createState() => _TodoFilterSheetState();
}

class _TodoFilterSheetState extends ConsumerState<TodoFilterSheet> {
  late Set<String> _selectedCategories;
  late Set<TodoPriority> _selectedPriorities;

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set.of(widget.initialCategories);
    _selectedPriorities = Set.of(widget.initialPriorities);
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_selectedCategories.contains(id)) {
        _selectedCategories.remove(id);
      } else {
        _selectedCategories.add(id);
      }
    });
  }

  void _togglePriority(TodoPriority p) {
    setState(() {
      if (_selectedPriorities.contains(p)) {
        _selectedPriorities.remove(p);
      } else {
        _selectedPriorities.add(p);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final config = ref.watch(todoConfigProvider);
    final categories = config.config.categories;
    final hasFilter = _selectedCategories.isNotEmpty ||
        _selectedPriorities.isNotEmpty;

    // 紧凑布局：分类一节 + 优先级一节，每行用 wrap 排列 FilterChip。
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('筛选', style: textTheme.titleMedium),
              const Spacer(),
              if (hasFilter)
                AdaptiveButton(
                  variant: AdaptiveButtonVariant.text,
                  label: '清除',
                  onPressed: () => setState(() {
                    _selectedCategories.clear();
                    _selectedPriorities.clear();
                  }),
                ),
              AdaptiveButton(
                variant: AdaptiveButtonVariant.text,
                label: '确定',
                onPressed: () => Navigator.of(context).pop(
                  (
                    categories: _selectedCategories,
                    priorities: _selectedPriorities,
                  ),
                ),
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('分类', style: textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      // 「无分类」
                      FilterChip(
                        label: const Text('无分类'),
                        selected: _selectedCategories.contains(todoNoCategoryKey),
                        onSelected: (_) => _toggleCategory(todoNoCategoryKey),
                      ),
                      for (final c in categories)
                        FilterChip(
                          showCheckmark: false,
                          avatar: CircleAvatar(
                            backgroundColor: Color(c.colorValue),
                            radius: 6,
                          ),
                          label: Text(c.name),
                          selected: _selectedCategories.contains(c.id),
                          onSelected: (_) => _toggleCategory(c.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('优先级', style: textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final p in TodoPriority.values)
                        FilterChip(
                          showCheckmark: false,
                          avatar: CircleAvatar(
                            backgroundColor: _priorityChipColor(p, colorScheme),
                            radius: 6,
                          ),
                          label: Text(p.displayName),
                          selected: _selectedPriorities.contains(p),
                          onSelected: (_) => _togglePriority(p),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color? _priorityChipColor(TodoPriority p, ColorScheme cs) =>
      switch (p) {
        TodoPriority.highest => cs.error,
        TodoPriority.high => cs.errorContainer,
        TodoPriority.medium => cs.tertiary,
        TodoPriority.normal => cs.onSurfaceVariant,
        TodoPriority.daily => cs.secondary,
      };
}

/// 筛选状态条（水平滚动，支持滚轮转水平滚动 + 拖动，紧凑样式）。
///
/// 在主页、待办汇总页、待办历史页复用。
class TodoFilterStatusBar extends StatefulWidget {
  const TodoFilterStatusBar({
    super.key,
    required this.activeFilters,
    required this.onRemoveFilter,
    required this.onClearFilters,
  });

  final List<TodoFilterEntry> activeFilters;
  final ValueChanged<String> onRemoveFilter;
  final VoidCallback onClearFilters;

  @override
  State<TodoFilterStatusBar> createState() => _TodoFilterStatusBarState();
}

class _TodoFilterStatusBarState extends State<TodoFilterStatusBar> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent &&
                      _scrollController.hasClients) {
                    final dy = event.scrollDelta.dy;
                    final dx = event.scrollDelta.dx;
                    final delta = dx != 0 ? dx : -dy;
                    if (delta == 0) return;
                    _scrollController.jumpTo(
                      (_scrollController.offset + delta).clamp(
                        0.0,
                        _scrollController.position.maxScrollExtent,
                      ),
                    );
                  }
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final f in widget.activeFilters)
                        Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: InputChip(
                            key: ValueKey(f.key),
                            label: Text(
                              f.label,
                              style: textTheme.labelLarge,
                            ),
                            labelPadding: EdgeInsets.zero,
                            avatar: f.color == null
                                ? null
                                : Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: f.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                            onDeleted: () => widget.onRemoveFilter(f.key),
                            deleteIcon: Icon(
                              Icons.close,
                              size: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AdaptiveIconButton(
            icon: const Icon(Icons.clear_all, size: 18),
            tooltip: '清除全部筛选',
            onPressed: widget.onClearFilters,
          ),
        ],
      ),
    );
  }
}
