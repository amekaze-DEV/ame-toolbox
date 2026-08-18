import 'package:ametoolbox/core/notifications/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_pattern.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_rule.dart';
import 'package:todo_list_module/features/todo_list/models/todo_config.dart';
import 'package:todo_list_module/features/todo_list/models/todo_item.dart';
import 'package:todo_list_module/features/todo_list/models/todo_priority.dart';
import 'package:todo_list_module/features/todo_list/services/recurrence_date_calculator.dart';
import 'package:todo_list_module/features/todo_list/services/todo_recurrence_resolver.dart';
import 'package:todo_list_module/features/todo_list/services/todo_reminder_service.dart';

/// 记录通知调用的 fake，用于断言 schedule/cancel。
class RecordingNotificationService implements NotificationService {
  final scheduled = <({String id, String title, String body, DateTime time})>[];
  final cancelled = <String>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> show(String id, String title, String body) async {}

  @override
  Future<void> schedule(
    String id,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    scheduled.add((id: id, title: title, body: body, time: scheduledTime));
  }

  @override
  Future<void> cancel(String id) async {
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelled.clear();
  }
}

void main() {
  const resolver = TodoRecurrenceResolver(
    calculator: RecurrenceDateCalculator(),
  );
  late RecordingNotificationService notifications;
  late TodoReminderService service;
  final now = DateTime(2026, 8, 12, 10, 0);
  final config = TodoConfig(remindEnabled: true);

  setUp(() {
    notifications = RecordingNotificationService();
    service = TodoReminderService(
      notificationService: notifications,
      resolver: resolver,
    );
  });

  TodoItem item({
    String id = 'todo-1',
    DateTime? dueDate,
    List<RecurrenceRule> rules = const [],
    int? remindMinutes,
    bool remindEnabled = true,
    int executionTimeMinutes = 540, // 09:00
    bool remindAtExecution = true,
    bool remindEarly = true,
    bool completed = false,
  }) {
    return TodoItem(
      id: id,
      title: '提醒事项',
      priority: TodoPriority.medium,
      dueDate: dueDate,
      recurrenceRules: rules,
      remindMinutes: remindMinutes,
      remindEnabled: remindEnabled,
      executionTimeMinutes: executionTimeMinutes,
      remindAtExecution: remindAtExecution,
      remindEarly: remindEarly,
      isCompleted: completed,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 8, 1),
    );
  }

  group('TodoReminderService', () {
    test('notificationId 遵循约定', () {
      expect(
        TodoReminderService.notificationId('abc'),
        'module_todo_list_item_abc',
      );
      expect(
        TodoReminderService.earlyNotificationId('abc'),
        'module_todo_list_item_abc_early',
      );
      expect(
        TodoReminderService.onTimeNotificationId('abc'),
        'module_todo_list_item_abc_onTime',
      );
    });

    test('一次性事项：执行时刻提醒 = 到期日 + 执行时刻（默认 09:00）', () {
      final time = service.executionReminderTime(
        item(dueDate: DateTime(2026, 8, 15)),
        config,
        now,
      );
      expect(time, DateTime(2026, 8, 15, 9, 0));
    });

    test('执行时刻可自定义', () {
      final time = service.executionReminderTime(
        item(
          dueDate: DateTime(2026, 8, 15),
          executionTimeMinutes: 14 * 60 + 30, // 14:30
        ),
        config,
        now,
      );
      expect(time, DateTime(2026, 8, 15, 14, 30));
    });

    test('一次性事项：提前提醒 = 执行时刻 - 提前分钟', () {
      final time = service.earlyReminderTime(
        item(dueDate: DateTime(2026, 8, 15), remindMinutes: 30),
        config,
        now,
      );
      expect(time, DateTime(2026, 8, 15, 8, 30));
    });

    test('提前提醒未设分钟数使用全局默认', () {
      final time = service.earlyReminderTime(
        item(dueDate: DateTime(2026, 8, 15)),
        config, // 默认 30 分钟
        now,
      );
      expect(time, DateTime(2026, 8, 15, 8, 30));
    });

    test('循环事项：按下一最近命中日的执行时刻计算', () {
      final rules = [
        RecurrenceRule(
          pattern: const MonthlyDayPattern(interval: 1, days: {15}),
          startDate: DateTime(2026, 1, 1),
        ),
      ];
      final execution = service.executionReminderTime(
        item(rules: rules),
        config,
        now,
      );
      // 下一命中 8/15，执行时刻 09:00
      expect(execution, DateTime(2026, 8, 15, 9, 0));

      final early = service.earlyReminderTime(
        item(rules: rules, remindMinutes: 60),
        config,
        now,
      );
      expect(early, DateTime(2026, 8, 15, 8, 0));
    });

    test('全局提醒关或单条开关关返回 null', () {
      final disabled = TodoConfig(remindEnabled: false);
      expect(
        service.executionReminderTime(
          item(dueDate: DateTime(2026, 8, 15)),
          disabled,
          now,
        ),
        isNull,
      );
      expect(
        service.executionReminderTime(
          item(dueDate: DateTime(2026, 8, 15), remindEnabled: false),
          config,
          now,
        ),
        isNull,
      );
      expect(
        service.earlyReminderTime(
          item(dueDate: DateTime(2026, 8, 15), remindEnabled: false),
          config,
          now,
        ),
        isNull,
      );
    });

    test('执行时刻提醒/提前提醒可独立关闭', () {
      // 关闭执行时刻提醒：执行时刻为 null，提前提醒仍有效
      expect(
        service.executionReminderTime(
          item(dueDate: DateTime(2026, 8, 15), remindAtExecution: false),
          config,
          now,
        ),
        isNull,
      );
      expect(
        service.earlyReminderTime(
          item(dueDate: DateTime(2026, 8, 15), remindAtExecution: false),
          config,
          now,
        ),
        DateTime(2026, 8, 15, 8, 30),
      );

      // 关闭提前提醒：提前提醒为 null，执行时刻提醒仍有效
      expect(
        service.executionReminderTime(
          item(dueDate: DateTime(2026, 8, 15), remindEarly: false),
          config,
          now,
        ),
        DateTime(2026, 8, 15, 9, 0),
      );
      expect(
        service.earlyReminderTime(
          item(dueDate: DateTime(2026, 8, 15), remindEarly: false),
          config,
          now,
        ),
        isNull,
      );
    });

    test('已完成或无期限/无命中返回 null', () {
      expect(
        service.executionReminderTime(
          item(dueDate: DateTime(2026, 8, 15), completed: true),
          config,
          now,
        ),
        isNull,
      );
      expect(service.executionReminderTime(item(), config, now), isNull);
      expect(service.earlyReminderTime(item(), config, now), isNull);
    });

    test('scheduleForItem 同时调度执行时刻与提前两条提醒', () async {
      await service.scheduleForItem(
        item(dueDate: DateTime(2026, 8, 15)),
        config,
        now,
      );
      expect(notifications.scheduled.length, 2);
      final ids = notifications.scheduled.map((e) => e.id).toSet();
      expect(ids, {
        'module_todo_list_item_todo-1_early',
        'module_todo_list_item_todo-1_onTime',
      });
    });

    test('关闭执行时刻提醒时仅调度提前提醒并取消另一条', () async {
      await service.scheduleForItem(
        item(dueDate: DateTime(2026, 8, 15), remindAtExecution: false),
        config,
        now,
      );
      expect(
        notifications.scheduled.map((e) => e.id),
        ['module_todo_list_item_todo-1_early'],
      );
      expect(
        notifications.cancelled,
        contains('module_todo_list_item_todo-1_onTime'),
      );
    });

    test('无提醒时取消两条通知', () async {
      await service.scheduleForItem(item(), config, now);
      expect(notifications.cancelled, containsAll([
        'module_todo_list_item_todo-1_early',
        'module_todo_list_item_todo-1_onTime',
      ]));
      expect(notifications.scheduled, isEmpty);
    });

    test('cancel 取消该待办全部通知 id', () async {
      await service.cancel('todo-1');
      expect(notifications.cancelled, containsAll([
        'module_todo_list_item_todo-1',
        'module_todo_list_item_todo-1_early',
        'module_todo_list_item_todo-1_onTime',
      ]));
    });
  });
}
