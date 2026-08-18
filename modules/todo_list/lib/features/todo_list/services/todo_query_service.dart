import '../models/todo_item.dart';
import '../models/todo_list_summary.dart';
import '../models/todo_priority.dart';
import 'todo_recurrence_resolver.dart';

/// 待办查询 / 排序 / 摘要服务（纯函数）。
///
/// - 优先级排序：默认 最高→高→中→一般→日常；支持"日常置顶"。
/// - 过期判定：未完成且期限早于今天。
/// - 摘要聚合：[TodoListSummary]。
class TodoQueryService {
  TodoQueryService({required this.resolver});

  final TodoRecurrenceResolver resolver;

  /// 优先级权重（默认顺序：最高最小）。
  static int _weight(TodoPriority p) => switch (p) {
        TodoPriority.highest => 0,
        TodoPriority.high => 1,
        TodoPriority.medium => 2,
        TodoPriority.normal => 3,
        TodoPriority.daily => 4,
      };

  /// 按优先级排序（不改动原列表）。
  ///
  /// [dailyTop] 为 true 时，日常事项整体置顶，其余仍按默认顺序；
  /// 同优先级按创建时间升序。
  List<TodoItem> sortByPriority(List<TodoItem> items, {bool dailyTop = false}) {
    final sorted = List<TodoItem>.of(items);
    sorted.sort((a, b) {
      if (dailyTop) {
        if (a.priority == TodoPriority.daily && b.priority != TodoPriority.daily) {
          return -1;
        }
        if (b.priority == TodoPriority.daily && a.priority != TodoPriority.daily) {
          return 1;
        }
      }
      final w = _weight(a.priority).compareTo(_weight(b.priority));
      if (w != 0) return w;
      return a.createdAt.compareTo(b.createdAt);
    });
    return sorted;
  }

  /// 是否已过期（未完成且期限早于 [now] 当天）。
  bool isOverdue(TodoItem item, DateTime now) {
    if (item.isCompleted) return false;
    final due = item.dueDate;
    if (due == null) return false;
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    return dueDay.isBefore(today);
  }

  /// 聚合摘要。
  ///
  /// [now] 用于过期与"今日"判定；循环事项是否命中今日由 [TodoRecurrenceResolver] 判定。
  TodoListSummary computeSummary(List<TodoItem> items, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    var total = 0, pending = 0, todayCount = 0, overdue = 0;
    for (final item in items) {
      if (item.isArchived) continue; // 历史不计入
      total++;
      final isPending = !item.isCompleted;
      if (isPending) pending++;
      if (isPending && isOverdue(item, now)) overdue++;
      // 今日待办：一次性按其 dueDate，循环按其解析命中今日。
      final dates = resolver.resolve(item, today, todayEnd);
      if (dates.isNotEmpty) todayCount++;
    }
    return TodoListSummary(
      total: total,
      pendingCount: pending,
      todayCount: todayCount,
      overdueCount: overdue,
    );
  }
}