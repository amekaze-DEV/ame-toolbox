import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_pattern.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_rule.dart';
import 'package:todo_list_module/features/todo_list/models/todo_image_attachment.dart';
import 'package:todo_list_module/features/todo_list/models/todo_item.dart';
import 'package:todo_list_module/features/todo_list/models/todo_priority.dart';

void main() {
  group('TodoItem', () {
    final createdAt = DateTime(2026, 8, 1, 9, 0);
    final updatedAt = DateTime(2026, 8, 12, 10, 0);
    final dueDate = DateTime(2026, 8, 15);
    final completedAt = DateTime(2026, 8, 14);

    test('一次性事项 toJson / fromJson 往返正确', () {
      final item = TodoItem(
        id: 'todo-1',
        title: '完成报告',
        details: '需要提交周报',
        images: [
          TodoImageAttachment(
            id: 'img-1',
            dataBase64: 'abc123',
            createdAt: createdAt,
          ),
        ],
        categoryId: 'work',
        priority: TodoPriority.high,
        dueDate: dueDate,
        remindMinutes: 30,
        remindEnabled: false,
        executionTimeMinutes: 480,
        remindAtExecution: false,
        remindEarly: true,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final json = item.toJson();
      expect(json['id'], 'todo-1');
      expect(json['title'], '完成报告');
      expect(json['details'], '需要提交周报');
      expect(json['categoryId'], 'work');
      expect(json['priority'], 'high');
      expect(json['dueDate'], '2026-08-15T00:00:00.000');
      expect(json['recurrenceRules'], isEmpty);
      expect(json['remindMinutes'], 30);
      expect(json['remindEnabled'], false);
      expect(json['executionTimeMinutes'], 480);
      expect(json['remindAtExecution'], false);
      expect(json['remindEarly'], true);
      expect(json['isCompleted'], false);

      final restored = TodoItem.fromJson(json);
      expect(restored.id, item.id);
      expect(restored.title, item.title);
      expect(restored.details, item.details);
      expect(restored.images.length, 1);
      expect(restored.categoryId, item.categoryId);
      expect(restored.priority, item.priority);
      expect(restored.dueDate, item.dueDate);
      expect(restored.isOneTime, true);
      expect(restored.isRecurring, false);
      expect(restored.remindMinutes, 30);
      expect(restored.remindEnabled, false);
      expect(restored.executionTimeMinutes, 480);
      expect(restored.remindAtExecution, false);
      expect(restored.remindEarly, true);
    });

    test('提醒字段缺失时使用默认值（向后兼容）', () {
      final item = TodoItem.fromJson({
        'id': 'legacy',
        'title': '旧数据',
        'priority': 'medium',
        'createdAt': '2026-08-01T00:00:00.000',
        'updatedAt': '2026-08-01T00:00:00.000',
      });
      expect(item.remindEnabled, true);
      expect(item.executionTimeMinutes, 540);
      expect(item.remindAtExecution, true);
      expect(item.remindEarly, true);
    });

    test('循环事项 toJson / fromJson 往返正确', () {
      final item = TodoItem(
        id: 'todo-2',
        title: '周会',
        priority: TodoPriority.medium,
        recurrenceRules: [
          RecurrenceRule(
            pattern: const WeeklyPattern(interval: 1, weekdays: {1}),
            startDate: createdAt,
          ),
        ],
        isCompleted: true,
        completedAt: completedAt,
        isArchived: true,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final json = item.toJson();
      expect((json['recurrenceRules'] as List).length, 1);
      expect(json['isCompleted'], true);
      expect(json['completedAt'], '2026-08-14T00:00:00.000');
      expect(json['isArchived'], true);

      final restored = TodoItem.fromJson(json);
      expect(restored.isRecurring, true);
      expect(restored.isCompleted, true);
      expect(restored.completedAt, completedAt);
      expect(restored.isArchived, true);
    });

    test('copyWith 修改字段并保持其他字段不变', () {
      final item = TodoItem(
        id: 'todo-3',
        title: '原始标题',
        priority: TodoPriority.normal,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final updated = item.copyWith(title: '新标题', isCompleted: true);
      expect(updated.title, '新标题');
      expect(updated.isCompleted, true);
      expect(updated.priority, item.priority);
      expect(updated.id, item.id);
    });
  });
}