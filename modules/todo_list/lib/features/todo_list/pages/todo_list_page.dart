import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/layout/responsive_builder.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/todo_category.dart';
import '../models/todo_item.dart';
import '../models/todo_priority.dart';
import '../providers/todo_config_provider.dart';
import '../providers/todo_export_service_provider.dart';
import '../providers/todo_list_provider.dart';
import '../providers/todo_query_service_provider.dart';
import '../providers/todo_recurrence_resolver_provider.dart';
import '../providers/holiday_data_controller.dart';
import '../providers/holiday_data_provider.dart';
import '../providers/lunar_info_provider.dart';
import '../services/lunar_info_service.dart';
import '../services/todo_recurrence_resolver.dart';
import '../widgets/todo_empty_view.dart';
import '../widgets/todo_item_tile.dart';
import '../widgets/todo_list_filter.dart';
import '../widgets/todo_month_calendar_view.dart';
import 'todo_detail_page.dart';
import 'todo_detail_view_page.dart';

/// 主页面选中日期（本地 UI 状态）。
final _selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// 主页面当前显示月份（本地 UI 状态）。
final _displayMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// 日历视图层级（本地 UI 状态）。
final _calendarViewLevelProvider =
    StateProvider<CalendarViewLevel>((ref) => CalendarViewLevel.day);

/// 分类筛选（空集合表示不限）。
final _categoryFilterProvider = StateProvider<Set<String>>((ref) => const {});

/// 优先级筛选（空集合表示不限）。
final _priorityFilterProvider =
    StateProvider<Set<TodoPriority>>((ref) => const {});

/// 待办主页面：上半为类日历月视图，下半为所选日期的待办列表。
class TodoListPage extends ConsumerWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(todoListProvider);
    final config = ref.watch(todoConfigProvider);
    final resolver = ref.watch(todoRecurrenceResolverProvider);
    final query = ref.watch(todoQueryServiceProvider);
    final lunarService = ref.watch(lunarInfoServiceProvider);
    final holidayData = ref.watch(holidayDataProvider);

    final selectedDate = ref.watch(_selectedDateProvider);
    final displayMonth = ref.watch(_displayMonthProvider);
    final today = DateTime.now();

    final items = list.items;
    final markedDates = _markedForMonth(resolver, items, displayMonth);
    final dayItems = _itemsForDay(resolver, items, selectedDate);
    final categoryFilter = ref.watch(_categoryFilterProvider);
    final priorityFilter = ref.watch(_priorityFilterProvider);
    final filtered = applyTodoFilters(dayItems, categoryFilter, priorityFilter);
    final sorted = query.sortByPriority(
      filtered,
      dailyTop: config.config.dailyTop,
    );

    // 当月每天的农历/节气/节日/节假日附加信息。
    final dayExtras = _dayExtrasForMonth(
      lunarService,
      holidayData,
      displayMonth,
    );

    final colorScheme = Theme.of(context).colorScheme;
    final activeFilters = buildFilterEntries(
      categoryFilter,
      priorityFilter,
      config.config.categories,
      colorScheme,
    );

    return ResponsiveBuilder(
      portraitBuilder: (context) => _buildScaffold(
        context,
        ref,
        markedDates: markedDates,
        displayMonth: displayMonth,
        selectedDate: selectedDate,
        today: today,
        itemsForDay: sorted,
        categories: config.config.categories,
        activeFilters: activeFilters,
        dayExtras: dayExtras,
        onOpenFilter: () => _openFilter(context, ref),
        horizontal: false,
      ),
      landscapeBuilder: (context) => _buildScaffold(
        context,
        ref,
        markedDates: markedDates,
        displayMonth: displayMonth,
        selectedDate: selectedDate,
        today: today,
        itemsForDay: sorted,
        categories: config.config.categories,
        activeFilters: activeFilters,
        dayExtras: dayExtras,
        onOpenFilter: () => _openFilter(context, ref),
        horizontal: true,
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    WidgetRef ref, {
    required Map<DateTime, TodoPriority> markedDates,
    required DateTime displayMonth,
    required DateTime selectedDate,
    required DateTime today,
    required List<TodoItem> itemsForDay,
    required List<TodoCategory> categories,
    required List<({String key, String label, Color? color})> activeFilters,
    required Map<DateTime, TodoDayExtra> dayExtras,
    required VoidCallback onOpenFilter,
    required bool horizontal,
  }) {
    final viewLevel = ref.watch(_calendarViewLevelProvider);
    final calendar = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TodoMonthCalendarView(
        displayMonth: displayMonth,
        selectedDate: selectedDate,
        today: today,
        markedDates: markedDates,
        dayExtras: dayExtras,
        viewLevel: viewLevel,
        onSelectDate: (date) {
          ref.read(_selectedDateProvider.notifier).state = date;
          // 日视图选中日期后始终回到日视图。
          ref.read(_calendarViewLevelProvider.notifier).state =
              CalendarViewLevel.day;
          // 选中跨月时同步翻月
          if (date.month != displayMonth.month) {
            ref.read(_displayMonthProvider.notifier).state =
                DateTime(date.year, date.month, 1);
          }
        },
        onTitleTap: () => _onTitleTap(ref),
        onMonthSelected: (month) => _onMonthSelected(ref, month),
        onYearSelected: (year) => _onYearSelected(ref, year),
        onPreviousUnit: () => _onPreviousUnit(ref),
        onNextUnit: () => _onNextUnit(ref),
        onToday: () => _onToday(ref),
        onDateJump: (date) {
          // 日期转跳：选中目标日期、翻月到目标所在月并回到日视图。
          ref.read(_selectedDateProvider.notifier).state = date;
          ref.read(_displayMonthProvider.notifier).state =
              DateTime(date.year, date.month, 1);
          ref.read(_calendarViewLevelProvider.notifier).state =
              CalendarViewLevel.day;
        },
      ),
    );

    final listSection = _DayListSection(
      items: itemsForDay,
      categories: categories,
      selectedDate: selectedDate,
      onAdd: () => _openAdd(context, ref),
      onOpenFilter: onOpenFilter,
      onItemTap: (item) => _openView(context, ref, item),
      onToggleComplete: (item, _) =>
          _confirmComplete(context, ref, item, selectedDate),
      onEdit: (item) => _openDetail(context, ref, item),
      onDelete: (item) => _confirmDelete(context, ref, item),
      onExportDay: () => _exportDay(context, ref, itemsForDay),
      activeFilters: activeFilters,
      onRemoveFilter: (key) => _removeFilter(ref, key),
      onClearFilters: () => _clearFilters(ref),
    );

    return Scaffold(
      body: horizontal
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  // 日视图置于可滚动容器；月/年视图为自适应缩放网格，无需滚动。
                  child: viewLevel == CalendarViewLevel.day
                      ? SingleChildScrollView(child: calendar)
                      : calendar,
                ),
                VerticalDivider(width: 1),
                Expanded(child: listSection),
              ],
            )
          : Column(
              children: [
                calendar,
                const Divider(height: 1),
                Expanded(child: listSection),
              ],
            ),
    );
  }

  /// 标题点击：日→月、月→年、年无操作。
  void _onTitleTap(WidgetRef ref) {
    switch (ref.read(_calendarViewLevelProvider)) {
      case CalendarViewLevel.day:
        ref.read(_calendarViewLevelProvider.notifier).state =
            CalendarViewLevel.month;
      case CalendarViewLevel.month:
        ref.read(_calendarViewLevelProvider.notifier).state =
            CalendarViewLevel.year;
      case CalendarViewLevel.year:
        break;
    }
  }

  /// 月份格选中：聚焦该月并返回日视图。
  void _onMonthSelected(WidgetRef ref, int month) {
    final displayMonth = ref.read(_displayMonthProvider);
    ref.read(_displayMonthProvider.notifier).state =
        DateTime(displayMonth.year, month, 1);
    ref.read(_calendarViewLevelProvider.notifier).state =
        CalendarViewLevel.day;
  }

  /// 年份格选中：聚焦该年并返回月视图。
  void _onYearSelected(WidgetRef ref, int year) {
    final displayMonth = ref.read(_displayMonthProvider);
    ref.read(_displayMonthProvider.notifier).state =
        DateTime(year, displayMonth.month, 1);
    ref.read(_calendarViewLevelProvider.notifier).state =
        CalendarViewLevel.month;
  }

  /// 层级感知的向前导航：day ±1 月、month ±1 年、year ±10 年。
  void _onPreviousUnit(WidgetRef ref) {
    final displayMonth = ref.read(_displayMonthProvider);
    final delta = switch (ref.read(_calendarViewLevelProvider)) {
      CalendarViewLevel.day => -1,
      CalendarViewLevel.month => -12,
      CalendarViewLevel.year => -120,
    };
    ref.read(_displayMonthProvider.notifier).state = DateTime(
      displayMonth.year,
      displayMonth.month + delta,
      1,
    );
  }

  /// 层级感知的向后导航：day ±1 月、month ±1 年、year ±10 年。
  void _onNextUnit(WidgetRef ref) {
    final displayMonth = ref.read(_displayMonthProvider);
    final delta = switch (ref.read(_calendarViewLevelProvider)) {
      CalendarViewLevel.day => 1,
      CalendarViewLevel.month => 12,
      CalendarViewLevel.year => 120,
    };
    ref.read(_displayMonthProvider.notifier).state = DateTime(
      displayMonth.year,
      displayMonth.month + delta,
      1,
    );
  }

  /// 「今天」：任意层级回日视图并聚焦今天。
  void _onToday(WidgetRef ref) {
    final now = DateTime.now();
    ref.read(_displayMonthProvider.notifier).state =
        DateTime(now.year, now.month, 1);
    ref.read(_calendarViewLevelProvider.notifier).state =
        CalendarViewLevel.day;
  }

  void _openAdd(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.read(_selectedDateProvider);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TodoDetailPage(defaultDueDate: selectedDate),
      ),
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref, TodoItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TodoDetailPage(item: item),
      ),
    );
  }

  void _openView(BuildContext context, WidgetRef ref, TodoItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TodoDetailViewPage(item: item),
      ),
    );
  }

  /// 导出当日待办为 Markdown（仅限所选日期当日，不含其他日期）。
  Future<void> _exportDay(
    BuildContext context,
    WidgetRef ref,
    List<TodoItem> items,
  ) async {
    final markdown = ref.read(todoExportServiceProvider).toMarkdown(items);
    await Clipboard.setData(ClipboardData(text: markdown));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制当日待办 Markdown 到剪贴板')),
      );
    }
  }

  /// 打开分类 / 优先级复选筛选面板。
  Future<void> _openFilter(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<TodoFilterSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TodoFilterSheet(
        initialCategories: ref.read(_categoryFilterProvider),
        initialPriorities: ref.read(_priorityFilterProvider),
      ),
    );
    if (result == null) return;
    ref.read(_categoryFilterProvider.notifier).state = result.categories;
    ref.read(_priorityFilterProvider.notifier).state = result.priorities;
  }

  /// 移除单个筛选条件（按筛选条目标识 key）。
  void _removeFilter(WidgetRef ref, String key) {
    if (key == 'cat_none') {
      final next = Set<String>.of(ref.read(_categoryFilterProvider))
        ..remove(todoNoCategoryKey);
      ref.read(_categoryFilterProvider.notifier).state = next;
    } else if (key.startsWith('cat_')) {
      final next = Set<String>.of(ref.read(_categoryFilterProvider))
        ..remove(key.substring(4));
      ref.read(_categoryFilterProvider.notifier).state = next;
    } else if (key.startsWith('pri_')) {
      final p = TodoPriority.values.firstWhere(
        (e) => e.name == key.substring(4),
      );
      final next = Set<TodoPriority>.of(ref.read(_priorityFilterProvider))
        ..remove(p);
      ref.read(_priorityFilterProvider.notifier).state = next;
    }
  }

  /// 一键清除全部筛选。
  void _clearFilters(WidgetRef ref) {
    ref.read(_categoryFilterProvider.notifier).state = const {};
    ref.read(_priorityFilterProvider.notifier).state = const {};
  }

  /// 完成确认销项：弹窗确认后销项。
  ///
  /// 循环类型仅销项「所选日期」的当次实例；一次性事项销项本身。
  void _confirmComplete(
    BuildContext context,
    WidgetRef ref,
    TodoItem item,
    DateTime day,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('完成确认'),
        content: Text(
          item.isRecurring
              ? '确认完成"${item.title}"本次事项吗？\n仅销项本次，循环将继续。'
              : '确认完成"${item.title}"吗？\n完成后将销项并移入待办历史。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(todoListProvider).completeOccurrence(item, day);
            },
            child: const Text('完成'),
          ),
        ],
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

  // ── 计算辅助 ──

  /// 当月日历显示网格的日期范围（含上周/下周补位日期）。
  ///
  /// 返回 (起始日期, 结束日期)，起始日对齐到周一，结束日补满当周周日。
  static (DateTime, DateTime) _gridRangeForMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1; // 周一开头
    final total = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;
    final gridStart = firstDay.subtract(Duration(days: leadingBlanks));
    final gridEnd = gridStart.add(Duration(days: total - 1));
    return (gridStart, gridEnd);
  }

  /// 生成当月日历网格内每天（含补位日期）的农历/节气/节日/节假日附加信息。
  static Map<DateTime, TodoDayExtra> _dayExtrasForMonth(
    LunarInfoService lunarService,
    HolidayDataController holidayData,
    DateTime month,
  ) {
    final (gridStart, gridEnd) = _gridRangeForMonth(month);
    final result = <DateTime, TodoDayExtra>{};
    var date = gridStart;
    while (!date.isAfter(gridEnd)) {
      result[date] = TodoDayExtra(
        lunarDate: lunarService.getLunarDate(date),
        solarTerm: lunarService.getSolarTerm(date),
        solarFestivals: lunarService.getSolarFestivals(date),
        holiday: holidayData.getHoliday(date),
      );
      date = date.add(const Duration(days: 1));
    }
    return result;
  }

  static bool _hitsOn(TodoRecurrenceResolver resolver, TodoItem item, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59);
    return resolver.resolve(item, start, end).isNotEmpty;
  }

  static String _ymd(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';

  /// 当月日历网格内每天的最高优先级映射（用于日历标记）。
  ///
  /// 优先级顺序固定：最高 > 高 > 中 > 一般 > 日常，日常为最低。
  /// 覆盖上月/下月补位日期，循环模板：若某日的实例已销项（归档），则该日不再标记。
  static Map<DateTime, TodoPriority> _markedForMonth(
    TodoRecurrenceResolver resolver,
    List<TodoItem> items,
    DateTime month,
  ) {
    final (gridStart, gridEnd) = _gridRangeForMonth(month);
    final start = DateTime(gridStart.year, gridStart.month, gridStart.day);
    final end = DateTime(gridEnd.year, gridEnd.month, gridEnd.day, 23, 59, 59);
    final marked = <DateTime, TodoPriority>{};
    for (final item in items) {
      if (item.isArchived) continue;
      for (final d in resolver.resolve(item, start, end)) {
        final day = DateTime(d.year, d.month, d.day);
        if (item.isRecurring &&
            items.any((e) =>
                e.id == '${item.id}_${_ymd(d)}' && e.isArchived)) {
          continue;
        }
        // 取当日最高优先级（枚举声明顺序即由高到低）。
        final current = marked[day];
        if (current == null || item.priority.index < current.index) {
          marked[day] = item.priority;
        }
      }
    }
    return marked;
  }

  /// 选中日期的待办列表（模板当日有实例则显示实例、跳过模板，避免重复）。
  static List<TodoItem> _itemsForDay(
    TodoRecurrenceResolver resolver,
    List<TodoItem> items,
    DateTime day,
  ) {
    final result = <TodoItem>[];
    for (final item in items) {
      if (item.isArchived) continue;
      if (!_hitsOn(resolver, item, day)) continue;
      if (item.isRecurring) {
        final instanceId = '${item.id}_${_ymd(day)}';
        if (items.any((e) => e.id == instanceId)) continue;
      }
      result.add(item);
    }
    return result;
  }
}

/// 所选日期的待办列表区块。
class _DayListSection extends StatefulWidget {
  const _DayListSection({
    required this.items,
    required this.categories,
    required this.selectedDate,
    required this.onAdd,
    required this.onOpenFilter,
    required this.onItemTap,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    required this.onExportDay,
    required this.activeFilters,
    required this.onRemoveFilter,
    required this.onClearFilters,
  });

  final List<TodoItem> items;
  final List<TodoCategory> categories;
  final DateTime selectedDate;
  final VoidCallback onAdd;

  /// 打开筛选面板。
  final VoidCallback onOpenFilter;

  final ValueChanged<TodoItem> onItemTap;

  /// 完成回调：`(item, 所选日期)`。
  final void Function(TodoItem item, DateTime date) onToggleComplete;
  final ValueChanged<TodoItem> onEdit;
  final ValueChanged<TodoItem> onDelete;

  /// 导出当日待办回调。
  final VoidCallback onExportDay;

  /// 当前生效的筛选条目列表。
  final List<({String key, String label, Color? color})> activeFilters;

  /// 移除单个筛选条目。
  final ValueChanged<String> onRemoveFilter;

  /// 一键清除全部筛选。
  final VoidCallback onClearFilters;

  @override
  State<_DayListSection> createState() => _DayListSectionState();

  static bool _isOverdue(TodoItem item, DateTime day) {
    if (item.isCompleted) return false;
    final due = item.dueDate;
    if (due == null) return false;
    final dueDay = DateTime(due.year, due.month, due.day);
    final dayOnly = DateTime(day.year, day.month, day.day);
    return dueDay.isBefore(dayOnly);
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

class _DayListSectionState extends State<_DayListSection> {
  /// 筛选状态条的水平滚动控制器（支持滚轮转水平滚动 + 拖动）。
  final _filterScrollController = ScrollController();

  @override
  void dispose() {
    _filterScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final items = widget.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.selectedDate.month}月${widget.selectedDate.day}日待办',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium,
                ),
              ),
              AdaptiveIconButton(
                icon: Icon(
                  widget.activeFilters.isNotEmpty
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                ),
                tooltip: '筛选',
                onPressed: widget.onOpenFilter,
              ),
              AdaptiveIconButton(
                icon: const Icon(Icons.add),
                tooltip: '新增待办',
                onPressed: widget.onAdd,
              ),
              if (items.isNotEmpty)
                AdaptiveIconButton(
                  icon: const Icon(Icons.copy_outlined),
                  tooltip: '导出当日待办为 Markdown',
                  onPressed: widget.onExportDay,
                ),
            ],
          ),
        ),
        // 筛选状态条（鼠标滚轮转水平滚动 + 拖动，紧凑样式）
        if (widget.activeFilters.isNotEmpty)
          Padding(
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
                            _filterScrollController.hasClients) {
                          final dy = event.scrollDelta.dy;
                          final dx = event.scrollDelta.dx;
                          // 优先水平滚轮位移；垂直滚轮取反映射为水平滚动。
                          final delta = dx != 0 ? dx : -dy;
                          if (delta == 0) return;
                          _filterScrollController.jumpTo(
                            (_filterScrollController.offset + delta).clamp(
                              0.0,
                              _filterScrollController
                                  .position.maxScrollExtent,
                            ),
                          );
                        }
                      },
                      child: SingleChildScrollView(
                        controller: _filterScrollController,
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
                                  onDeleted: () =>
                                      widget.onRemoveFilter(f.key),
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
          ),
        Expanded(
          child: items.isEmpty
              ? TodoEmptyView(
                  message: widget.activeFilters.isNotEmpty
                      ? '筛选无匹配结果'
                      : '${widget.selectedDate.month}月${widget.selectedDate.day}日暂无待办',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final category =
                        _DayListSection._categoryById(widget.categories, item.categoryId);
                    return TodoItemTile(
                      item: item,
                      isOverdue:
                          _DayListSection._isOverdue(item, widget.selectedDate),
                      categoryName: category?.name,
                      categoryColor: category == null
                          ? null
                          : Color(category.colorValue),
                      onTap: () => widget.onItemTap(item),
                      onToggleComplete: () =>
                          widget.onToggleComplete(item, widget.selectedDate),
                      onEdit: () => widget.onEdit(item),
                      onDelete: () => widget.onDelete(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
