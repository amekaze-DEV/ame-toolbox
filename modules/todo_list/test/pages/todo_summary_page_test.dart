import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/providers/notification_provider.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/fake_device_info.dart';
import '../helpers/memory_storage_service.dart';
import '../helpers/noop_notification_service.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_pattern.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_rule.dart';
import 'package:todo_list_module/features/todo_list/models/todo_item.dart';
import 'package:todo_list_module/features/todo_list/models/todo_priority.dart';
import 'package:todo_list_module/features/todo_list/pages/todo_summary_page.dart';
import 'package:todo_list_module/features/todo_list/providers/todo_list_provider.dart';

void main() {
  late MemoryStorageService storage;

  setUp(() {
    storage = MemoryStorageService();
  });

  List<Override> overrides() => [
        storageServiceProvider.overrideWithValue(storage),
        deviceInfoProvider.overrideWithValue(FakeDeviceInfoProvider()),
        notificationServiceProvider.overrideWithValue(NoopNotificationService()),
      ];

  Future<ProviderContainer> seedItems(List<TodoItem> items) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    final controller = container.read(todoListProvider);
    for (final item in items) {
      await controller.add(item);
    }
    return container;
  }

  Widget wrap(Widget child, {ProviderContainer? container}) {
    final scope = container == null
        ? ProviderScope(overrides: overrides(), child: child)
        : UncontrolledProviderScope(container: container, child: child);
    return InputModeScope(mode: InputMode.touch, child: scope);
  }

  TodoItem makeItem({
    required String id,
    required String title,
    TodoPriority priority = TodoPriority.normal,
    String? categoryId,
    bool isArchived = false,
    bool isCompleted = false,
    bool isRecurring = false,
    DateTime? completedAt,
  }) {
    final now = DateTime.now();
    return TodoItem(
      id: id,
      title: title,
      priority: priority,
      categoryId: categoryId,
      isArchived: isArchived,
      isCompleted: isCompleted,
      completedAt: completedAt,
      recurrenceRules: isRecurring
          ? [
              RecurrenceRule(
                pattern: MonthlyDayPattern(interval: 1, days: {now.day}),
                startDate: DateTime(now.year, now.month, 1),
              ),
            ]
          : const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets('汇总页展示在运转的待办（单次 + 循环模板），不显示已归档', (tester) async {
    final container = await seedItems([
      makeItem(id: 'a', title: '运转单次'),
      makeItem(id: 'b', title: '运转循环', isRecurring: true),
      makeItem(id: 'c', title: '已关闭单次', isArchived: true),
    ]);

    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoSummaryPage()), container: container),
    );
    await tester.pumpAndSettle();

    expect(find.text('待办汇总'), findsOneWidget);
    expect(find.text('运转单次'), findsOneWidget);
    // 运转循环可能出现 2 次（标题列 + 副标题文本），用 findsWidgets
    expect(find.text('运转循环'), findsWidgets);
    expect(find.text('已关闭单次'), findsNothing);
  });

  testWidgets('汇总页按分类筛选后仅显示匹配项', (tester) async {
    final container = await seedItems([
      makeItem(id: 'a', title: '工作项', categoryId: 'work'),
      makeItem(id: 'b', title: '生活项', categoryId: 'life'),
    ]);

    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoSummaryPage()), container: container),
    );
    await tester.pumpAndSettle();

    // 打开筛选面板并选择「工作（分类）」
    await tester.tap(find.byTooltip('筛选'));
    await tester.pumpAndSettle();
    // 在筛选面板中找到「工作」FilterChip 并点击
    await tester.tap(find.widgetWithText(FilterChip, '工作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(find.text('工作项'), findsOneWidget);
    expect(find.text('生活项'), findsNothing);
    // 显示筛选状态条
    expect(find.widgetWithText(InputChip, '工作'), findsOneWidget);
  });

  testWidgets('汇总页空状态提示', (tester) async {
    await tester.pumpWidget(wrap(const MaterialApp(home: TodoSummaryPage())));
    await tester.pumpAndSettle();
    expect(find.text('暂无在运转的待办事项'), findsOneWidget);
  });

  testWidgets('历史页仅展示已关闭事项，循环单日实例不展示', (tester) async {
    final now = DateTime.now();
    final container = await seedItems([
      makeItem(id: 'one', title: '历史单次', isCompleted: true, completedAt: now),
      // 循环模板（仍在循环，未关闭）
      makeItem(id: 'rec', title: '循环模板', isRecurring: true),
      // 循环单日实例（仅单日完成，模板仍在循环）→ 不应记录
      makeItem(
        id: 'rec_20260801',
        title: '循环单日实例',
        isCompleted: true,
        completedAt: now,
      ),
      // 循环模板整系列关闭 → 记录
      makeItem(id: 'closed', title: '已关闭循环', isRecurring: true, isCompleted: true, completedAt: now),
    ]);

    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoSummaryPage()), container: container),
    );
    await tester.pumpAndSettle();

    // 进入历史页
    await tester.tap(find.text('待办历史'));
    await tester.pumpAndSettle();

    expect(find.text('待办历史'), findsOneWidget);
    expect(find.text('历史单次'), findsOneWidget);
    expect(find.text('已关闭循环'), findsOneWidget);
    // 循环单日实例不记录
    expect(find.text('循环单日实例'), findsNothing);
    // 仍在循环的模板不记录
    expect(find.text('循环模板'), findsNothing);
  });

  testWidgets('历史页引用创建新事项：预填且不保留期限循环', (tester) async {
    final now = DateTime.now();
    final container = await seedItems([
      makeItem(
        id: 'one',
        title: '历史事项',
        isCompleted: true,
        completedAt: now,
        priority: TodoPriority.high,
        categoryId: 'work',
      ),
    ]);

    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoSummaryPage()), container: container),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('待办历史'));
    await tester.pumpAndSettle();

    // 点击「引用」
    await tester.tap(find.text('引用'));
    await tester.pumpAndSettle();

    // 进入新增编辑页，标题已预填；循环类型为「一次性」
    expect(find.text('新增待办'), findsOneWidget);
    expect(find.text('历史事项'), findsWidgets);

    // 保存后新增一个未归档事项
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final items = container.read(todoListProvider).items;
    final created = items.firstWhere(
      (e) => e.title == '历史事项' && !e.isCompleted && e.id != 'one',
    );
    expect(created.dueDate, isNull);
    expect(created.recurrenceRules, isEmpty);
    expect(created.priority, TodoPriority.high);
    expect(created.categoryId, 'work');
  });

  testWidgets('历史页条目详情只读，不提供编辑按钮', (tester) async {
    final now = DateTime.now();
    final container = await seedItems([
      makeItem(id: 'one', title: '历史只读项', isCompleted: true, completedAt: now),
    ]);

    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoSummaryPage()), container: container),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('待办历史'));
    await tester.pumpAndSettle();

    // 点击条目进入详情查看页
    await tester.tap(find.text('历史只读项'));
    await tester.pumpAndSettle();

    // 只读展示，无「编辑」按钮
    expect(find.text('编辑'), findsNothing);
    expect(find.text('引用'), findsNothing);
    expect(find.text('详情'), findsOneWidget);
  });
}
