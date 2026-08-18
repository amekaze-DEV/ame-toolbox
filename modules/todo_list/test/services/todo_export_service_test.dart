import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_pattern.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_rule.dart';
import 'package:todo_list_module/features/todo_list/models/todo_item.dart';
import 'package:todo_list_module/features/todo_list/models/todo_priority.dart';
import 'package:todo_list_module/features/todo_list/services/todo_export_service.dart';

void main() {
  const service = TodoExportService();

  TodoItem item({
    String id = '1',
    String title = '待办',
    TodoPriority priority = TodoPriority.medium,
    bool completed = false,
    DateTime? dueDate,
    DateTime? completedAt,
    List<RecurrenceRule> rules = const [],
  }) {
    final now = DateTime(2026, 8, 12);
    return TodoItem(
      id: id,
      title: title,
      priority: priority,
      isCompleted: completed,
      dueDate: dueDate,
      completedAt: completedAt,
      recurrenceRules: rules,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('TodoExportService', () {
    test('空列表生成空文档结构', () {
      final md = service.toMarkdown([]);
      expect(md, contains('# 待办清单'));
      expect(md, contains('## 进行中'));
      expect(md, contains('- 暂无'));
      expect(md, contains('## 已完成'));
    });

    test('进行中项含优先级与截止信息', () {
      final md = service.toMarkdown([
        item(
          title: '完成报告',
          priority: TodoPriority.highest,
          dueDate: DateTime(2026, 8, 15),
        ),
      ]);
      expect(md, contains('- [ ] 完成报告（最高，2026-08-15 截止）'));
    });

    test('循环项含循环描述', () {
      final md = service.toMarkdown([
        item(
          title: '周会',
          rules: [
            RecurrenceRule(
              pattern: const WeeklyPattern(interval: 1, weekdays: {1}),
              startDate: DateTime(2026, 1, 1),
            ),
          ],
        ),
      ]);
      expect(md, contains('循环：每周的周一'));
    });

    test('已完成项归入已完成区', () {
      final md = service.toMarkdown([
        item(
          title: '已完成事',
          completed: true,
          completedAt: DateTime(2026, 8, 10),
        ),
      ]);
      expect(md, contains('- [x] 已完成事（2026-08-10）'));
      expect(md, isNot(contains('## 进行中\n- [x]')));
    });
  });
}