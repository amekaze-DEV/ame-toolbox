import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_pattern.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_rule.dart';
import 'package:todo_list_module/features/todo_list/models/todo_item.dart';
import 'package:todo_list_module/features/todo_list/models/todo_priority.dart';
import 'package:todo_list_module/features/todo_list/services/recurrence_date_calculator.dart';
import 'package:todo_list_module/features/todo_list/services/todo_query_service.dart';
import 'package:todo_list_module/features/todo_list/services/todo_recurrence_resolver.dart';

void main() {
  const resolver = TodoRecurrenceResolver(
    calculator: RecurrenceDateCalculator(),
  );
  final service = TodoQueryService(resolver: resolver);
  final now = DateTime(2026, 8, 12);

  TodoItem item({
    required String id,
    TodoPriority priority = TodoPriority.medium,
    bool completed = false,
    DateTime? dueDate,
    DateTime? createdAt,
    List<RecurrenceRule> rules = const [],
  }) {
    return TodoItem(
      id: id,
      title: id,
      priority: priority,
      isCompleted: completed,
      dueDate: dueDate,
      recurrenceRules: rules,
      createdAt: createdAt ?? DateTime(2026, 1, 1, 0, 0),
      updatedAt: createdAt ?? DateTime(2026, 1, 1, 0, 0),
    );
  }

  group('TodoQueryService.sortByPriority', () {
    test('默认顺序：最高→高→中→一般→日常', () {
      final items = [
        item(id: 'daily', priority: TodoPriority.daily),
        item(id: 'highest', priority: TodoPriority.highest),
        item(id: 'normal', priority: TodoPriority.normal),
        item(id: 'medium', priority: TodoPriority.medium),
        item(id: 'high', priority: TodoPriority.high),
      ];
      final sorted = service.sortByPriority(items);
      expect(
        sorted.map((e) => e.id).toList(),
        ['highest', 'high', 'medium', 'normal', 'daily'],
      );
    });

    test('日常置顶：daily 排最前，其余保持默认', () {
      final items = [
        item(id: 'daily-a', priority: TodoPriority.daily),
        item(id: 'highest', priority: TodoPriority.highest),
        item(id: 'daily-b', priority: TodoPriority.daily),
        item(id: 'normal', priority: TodoPriority.normal),
      ];
      final sorted = service.sortByPriority(items, dailyTop: true);
      final ids = sorted.map((e) => e.id).toList();
      expect(ids.first, 'daily-a'); // 日常置顶
      expect(ids[1], 'daily-b');
      expect(ids, contains('highest'));
      expect(ids, contains('normal'));
    });

    test('同优先级按创建时间升序', () {
      final items = [
        item(id: 'b', priority: TodoPriority.high, createdAt: DateTime(2026, 2, 1)),
        item(id: 'a', priority: TodoPriority.high, createdAt: DateTime(2026, 1, 1)),
      ];
      final sorted = service.sortByPriority(items);
      expect(sorted.map((e) => e.id).toList(), ['a', 'b']);
    });

    test('不修改原列表', () {
      final items = [
        item(id: 'daily', priority: TodoPriority.daily),
        item(id: 'highest', priority: TodoPriority.highest),
      ];
      service.sortByPriority(items);
      expect(items.map((e) => e.id).toList(), ['daily', 'highest']);
    });
  });

  group('TodoQueryService.isOverdue', () {
    test('未完成且期限在今天之前为过期', () {
      expect(
        service.isOverdue(
          item(id: 'a', dueDate: DateTime(2026, 8, 11)),
          now,
        ),
        true,
      );
    });

    test('期限为今天不算过期', () {
      expect(
        service.isOverdue(item(id: 'a', dueDate: DateTime(2026, 8, 12)), now),
        false,
      );
    });

    test('已完成不算过期', () {
      expect(
        service.isOverdue(
          item(id: 'a', completed: true, dueDate: DateTime(2026, 8, 1)),
          now,
        ),
        false,
      );
    });

    test('无期限不算过期', () {
      expect(service.isOverdue(item(id: 'a'), now), false);
    });
  });

  group('TodoQueryService.computeSummary', () {
    test('统计 total/pending/today/overdue', () {
      final items = [
        item(id: 'a', dueDate: DateTime(2026, 8, 12)), // 今日，未完成
        item(id: 'b', dueDate: DateTime(2026, 8, 1)), // 过期未完成
        item(id: 'c', completed: true), // 已完成
        item(
          id: 'd',
          rules: [
            RecurrenceRule(
              pattern: const MonthlyDayPattern(interval: 1, days: {12}),
              startDate: DateTime(2026, 1, 1),
            ),
          ],
        ), // 循环命中今日
      ];
      final s = service.computeSummary(items, now);
      expect(s.total, 4);
      expect(s.pendingCount, 3); // a,b,d 未完成
      expect(s.todayCount, 2); // a, d
      expect(s.overdueCount, 1); // b
    });

    test('历史项不计入摘要', () {
      final archived = item(id: 'a').copyWith(isArchived: true);
      final s = service.computeSummary([archived], now);
      expect(s.total, 0);
    });
  });
}