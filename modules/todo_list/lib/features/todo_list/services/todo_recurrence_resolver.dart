import '../models/todo_item.dart';
import 'recurrence_date_calculator.dart';

/// 多规则合并解析器。
///
/// 计算一个 [TodoItem] 在指定区间内的所有待办日期：
/// - 循环事项：对所有 [TodoItem.recurrenceRules] 独立调用
///   [RecurrenceDateCalculator]，结果合并去重、升序排列；
/// - 一次性事项：返回非空 [TodoItem.dueDate]（若在区间内）。
class TodoRecurrenceResolver {
  const TodoRecurrenceResolver({required this.calculator});

  final RecurrenceDateCalculator calculator;

  /// 解析 [item] 在 `[from, to]` 闭区间内的全部命中日期（升序去重）。
  List<DateTime> resolve(TodoItem item, DateTime from, DateTime to) {
    if (item.recurrenceRules.isEmpty) {
      final due = item.dueDate;
      if (due == null) return const [];
      final day = DateTime(due.year, due.month, due.day);
      if (day.isBefore(from) || day.isAfter(to)) return const [];
      return [day];
    }
    final allDates = <DateTime>{};
    for (final rule in item.recurrenceRules) {
      allDates.addAll(calculator.generateDates(rule, from, to));
    }
    return allDates.toList()..sort();
  }
}