import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_pattern.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_rule.dart';
import 'package:todo_list_module/features/todo_list/models/todo_item.dart';
import 'package:todo_list_module/features/todo_list/models/todo_priority.dart';
import 'package:todo_list_module/features/todo_list/services/recurrence_date_calculator.dart';
import 'package:todo_list_module/features/todo_list/services/todo_recurrence_resolver.dart';

void main() {
  const calculator = RecurrenceDateCalculator();
  const resolver = TodoRecurrenceResolver(calculator: calculator);
  final from = DateTime(2026, 1, 1);
  final to = DateTime(2026, 12, 31);

  TodoItem item({
    List<RecurrenceRule> rules = const [],
    DateTime? dueDate,
  }) {
    return TodoItem(
      id: 't',
      title: 't',
      priority: TodoPriority.medium,
      dueDate: dueDate,
      recurrenceRules: rules,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  group('TodoRecurrenceResolver', () {
    test('一次性事项返回区间内的 dueDate', () {
      final dates = resolver.resolve(
        item(dueDate: DateTime(2026, 3, 5)),
        from,
        to,
      );
      expect(dates, [DateTime(2026, 3, 5)]);
    });

    test('一次性事项无 dueDate 返回空', () {
      expect(resolver.resolve(item(), from, to), isEmpty);
    });

    test('一次性事项 dueDate 在区间外返回空', () {
      expect(resolver.resolve(item(dueDate: DateTime(2025, 3, 5)), from, to), isEmpty);
    });

    test('多规则合并去重升序：每周一 + 每月15号', () {
      final rules = [
        RecurrenceRule(
          pattern: const WeeklyPattern(interval: 1, weekdays: {1}),
          startDate: DateTime(2026, 1, 1),
        ),
        RecurrenceRule(
          pattern: const MonthlyDayPattern(interval: 1, days: {15}),
          startDate: DateTime(2026, 1, 1),
        ),
      ];
      final dates = resolver.resolve(item(rules: rules), from, to);
      // 2026-01-15 是周四，不是周一，不与周一并集冲突；但 2026-06-15 是周一需去重
      expect(dates, contains(DateTime(2026, 1, 15)));
      expect(dates, contains(DateTime(2026, 1, 5))); // 周一来
      expect(dates.toSet().length, dates.length); // 无重复
      for (var i = 1; i < dates.length; i++) {
        expect(dates[i].isAfter(dates[i - 1]), true); // 升序
      }
    });
  });
}