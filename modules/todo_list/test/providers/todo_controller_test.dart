import 'package:ametoolbox/core/notifications/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/memory_storage_service.dart';
import 'package:todo_list_module/features/todo_list/data/todo_config_repository.dart';
import 'package:todo_list_module/features/todo_list/data/todo_list_repository.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_pattern.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_rule.dart';
import 'package:todo_list_module/features/todo_list/models/todo_item.dart';
import 'package:todo_list_module/features/todo_list/models/todo_priority.dart';
import 'package:todo_list_module/features/todo_list/providers/todo_config_controller.dart';
import 'package:todo_list_module/features/todo_list/providers/todo_list_controller.dart';
import 'package:todo_list_module/features/todo_list/services/recurrence_date_calculator.dart';
import 'package:todo_list_module/features/todo_list/services/todo_recurrence_resolver.dart';
import 'package:todo_list_module/features/todo_list/services/todo_reminder_service.dart';

class _NoopNotificationService implements NotificationService {
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
  ) async {}

  @override
  Future<void> cancel(String id) async {}

  @override
  Future<void> cancelAll() async {}
}

void main() {
  late MemoryStorageService storage;
  late TodoConfigController configController;
  late TodoListController controller;

  setUp(() async {
    storage = MemoryStorageService();
    configController =
        TodoConfigController(TodoConfigRepository(storageService: storage));
    await configController.load();
    const resolver = TodoRecurrenceResolver(
      calculator: RecurrenceDateCalculator(),
    );
    final reminder = TodoReminderService(
      notificationService: _NoopNotificationService(),
      resolver: resolver,
    );
    controller = TodoListController(
      repository: TodoListRepository(storageService: storage),
      resolver: resolver,
      reminderService: reminder,
      configController: configController,
    );
  });

  TodoItem oneTime({
    String id = 'a',
    String title = '一次性',
    DateTime? dueDate,
  }) {
    final now = DateTime(2026, 8, 12);
    return TodoItem(
      id: id,
      title: title,
      priority: TodoPriority.medium,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
    );
  }

  TodoItem recurring({
    String id = 'tpl',
    String title = '循环',
    List<RecurrenceRule> rules = const [],
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id,
      title: title,
      priority: TodoPriority.medium,
      recurrenceRules: rules,
      createdAt: createdAt ?? DateTime(2026, 8, 1),
      updatedAt: createdAt ?? DateTime(2026, 8, 1),
    );
  }

  group('TodoConfigController', () {
    test('默认配置', () {
      expect(configController.config.categories.length, 3);
      expect(configController.config.remindEnabled, true);
    });

    test('setRemindEnabled 持久化并通知', () async {
      await configController.setRemindEnabled(false);
      expect(configController.config.remindEnabled, false);

      // 用新控制器从存储重新加载验证已持久化
      final reloaded = TodoConfigController(
        TodoConfigRepository(storageService: storage),
      );
      await reloaded.load();
      expect(reloaded.config.remindEnabled, false);
    });

    test('addCategory / updateCategory / deleteCategory', () async {
      await configController.addCategory('个人', colorValue: 0xFF123456);
      expect(configController.config.categories.length, 4);

      final added = configController.config.categories.last;
      await configController.updateCategory(
        added.copyWith(name: '个人已改'),
      );
      expect(configController.config.categories.last.name, '个人已改');

      await configController.deleteCategory(added.id);
      expect(configController.config.categories.length, 3);
    });

    test('reorderCategories 更新显示顺序', () async {
      // 初始 work/life/other
      await configController.reorderCategories(0, 2); // 把 work 移到末尾
      final ids = configController.config.categories.map((c) => c.id).toList();
      expect(ids, ['life', 'other', 'work']);
      expect(
        configController.config.categories.map((c) => c.displayOrder).toList(),
        [0, 1, 2],
      );
    });
  });

  group('TodoListController', () {
    test('add 持久化并可加载', () async {
      await controller.add(oneTime(id: 'a', title: '任务A'));
      expect(controller.items.length, 1);

      final reloaded = TodoListController(
        repository: TodoListRepository(storageService: storage),
        resolver: const TodoRecurrenceResolver(
          calculator: RecurrenceDateCalculator(),
        ),
        reminderService: TodoReminderService(
          notificationService: _NoopNotificationService(),
          resolver: const TodoRecurrenceResolver(
            calculator: RecurrenceDateCalculator(),
          ),
        ),
        configController: configController,
      );
      await reloaded.load();
      expect(reloaded.items.length, 1);
      expect(reloaded.items.first.title, '任务A');
    });

    test('toggleComplete 一次性事项完成标记', () async {
      await controller.add(oneTime(id: 'a'));
      await controller.toggleComplete('a');
      final item = controller.items.first;
      expect(item.isCompleted, true);
      expect(item.isArchived, false);
      expect(item.completedAt, isNotNull);

      // 取消完成恢复
      await controller.toggleComplete('a');
      final restored = controller.items.first;
      expect(restored.isCompleted, false);
      expect(restored.isArchived, false);
    });

    test('循环模板自动补齐实例', () async {
      final rule = RecurrenceRule(
        pattern: const MonthlyDayPattern(interval: 1, days: {1}),
        startDate: DateTime(2026, 8, 1),
      );
      // 模板创建于 8/1，今天 8/12，应补齐 8/1 实例
      await controller.add(recurring(id: 'tpl', rules: [rule]));
      final instanceIds = controller.items
          .where((e) => e.id.startsWith('tpl_'))
          .map((e) => e.id)
          .toList();
      expect(instanceIds, contains('tpl_20260801'));
      // 模板本身保留
      expect(controller.items.any((e) => e.id == 'tpl'), true);
    });

    test('删除循环模板连带删除实例', () async {
      final rule = RecurrenceRule(
        pattern: const MonthlyDayPattern(interval: 1, days: {1}),
        startDate: DateTime(2026, 8, 1),
      );
      await controller.add(recurring(id: 'tpl', rules: [rule]));
      expect(controller.items.length, 2); // 模板 + 8/1 实例

      await controller.delete('tpl');
      expect(controller.items, isEmpty);
    });

    test('完成循环模板仅销项当次实例，模板保持开启', () async {
      final rule = RecurrenceRule(
        pattern: const MonthlyDayPattern(interval: 1, days: {1}),
        startDate: DateTime(2026, 8, 1),
      );
      await controller.add(recurring(id: 'tpl', rules: [rule]));
      final template = controller.items.firstWhere((e) => e.id == 'tpl');
      expect(controller.items.any((e) => e.id == 'tpl_20260801'), true);

      await controller.completeOccurrence(template, DateTime(2026, 8, 1));

      // 模板不被关闭，循环继续
      expect(
        controller.items.firstWhere((e) => e.id == 'tpl').isArchived,
        false,
      );
      // 当次实例完成，模板保持开启
      final inst = controller.items.firstWhere((e) => e.id == 'tpl_20260801');
      expect(inst.isCompleted, true);
      expect(inst.isArchived, false);
    });

    test('toggleComplete 循环模板改为完成今天实例，不关模板', () async {
      final rule = RecurrenceRule(
        pattern: const MonthlyDayPattern(interval: 1, days: {1}),
        startDate: DateTime(2026, 8, 1),
      );
      await controller.add(recurring(id: 'tpl', rules: [rule]));
      await controller.toggleComplete('tpl');
      expect(
        controller.items.firstWhere((e) => e.id == 'tpl').isArchived,
        false,
      );
    });

    test('closeRecurring 关闭整个循环标记完成', () async {
      final rule = RecurrenceRule(
        pattern: const MonthlyDayPattern(interval: 1, days: {1}),
        startDate: DateTime(2026, 8, 1),
      );
      await controller.add(recurring(id: 'tpl', rules: [rule]));
      expect(controller.items.length, 2); // 模板 + 实例

      await controller.closeRecurring('tpl');
      for (final e in controller.items) {
        expect(e.isCompleted, true);
        expect(e.isArchived, false);
      }
    });

    test('update 更新待办项', () async {
      await controller.add(oneTime(id: 'a', title: '旧'));
      await controller.update(oneTime(id: 'a', title: '新'));
      expect(controller.items.first.title, '新');
    });

    test('import 按 updatedAt 较新者合并', () async {
      final now = DateTime(2026, 8, 12);
      await controller.add(
        oneTime(id: 'a', title: '本地旧').copyWith(updatedAt: now),
      );
      final remote = oneTime(id: 'a', title: '远端新')
          .copyWith(updatedAt: now.add(const Duration(days: 1)));
      final remoteNew = oneTime(id: 'b', title: '远端新增')
          .copyWith(updatedAt: now);

      await controller.import([remote, remoteNew]);
      final byId = {for (final e in controller.items) e.id: e};
      expect(byId['a']!.title, '远端新'); // 远端 updatedAt 更新
      expect(byId['b'], isNotNull); // 远端新增保留
    });
  });
}