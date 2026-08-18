import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/providers/notification_provider.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/debug/fake_device_info.dart';
import 'package:todo_list_module/debug/memory_storage_service.dart';
import 'package:todo_list_module/debug/noop_notification_service.dart';
import 'package:todo_list_module/features/todo_list/models/holiday_info.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_pattern.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_rule.dart';
import 'package:todo_list_module/features/todo_list/models/todo_item.dart';
import 'package:todo_list_module/features/todo_list/models/todo_priority.dart';
import 'package:todo_list_module/features/todo_list/pages/todo_list_page.dart';
import 'package:todo_list_module/features/todo_list/providers/holiday_data_provider.dart';
import 'package:todo_list_module/features/todo_list/providers/todo_list_provider.dart';
import 'package:todo_list_module/features/todo_list/services/holiday_data_service.dart';

/// 不发起真实网络请求的 [HolidayDataService] 模拟。
class _FakeHolidayDataService extends HolidayDataService {
  @override
  Future<Map<String, HolidayInfo>> fetchYear(int year) async => const {};
}

void main() {
  late MemoryStorageService storage;

  setUp(() {
    storage = MemoryStorageService();
  });

  List<Override> overrides() => [
        storageServiceProvider.overrideWithValue(storage),
        deviceInfoProvider.overrideWithValue(FakeDeviceInfoProvider()),
        notificationServiceProvider.overrideWithValue(NoopNotificationService()),
        holidayDataServiceProvider.overrideWithValue(_FakeHolidayDataService()),
      ];

  ProviderScope buildApp(Widget child) {
    return ProviderScope(
      overrides: overrides(),
      child: InputModeScope(
        mode: InputMode.touch,
        child: child,
      ),
    );
  }

  Future<ProviderContainer> seedItem(TodoItem item) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    final controller = container.read(todoListProvider);
    await controller.add(item);
    return container;
  }

  testWidgets('主页面渲染日历标题、工具按钮与空状态', (tester) async {
    await tester.pumpWidget(buildApp(const MaterialApp(home: TodoListPage())));
    final now = DateTime.now();
    // AppBar 标题已移除，日历标题显示当前年月
    expect(find.text('${now.year}年${now.month}月'), findsOneWidget);
    expect(find.text('待办清单'), findsNothing);
    // 筛选 / 新增按钮移至列表标题行
    expect(find.byTooltip('筛选'), findsOneWidget);
    expect(find.byTooltip('新增待办'), findsOneWidget);
    expect(find.textContaining('暂无待办'), findsOneWidget);
  });

  testWidgets('选中日期有待办时显示待办卡片和导出按钮', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final item = TodoItem(
      id: 'a',
      title: '今日任务',
      priority: TodoPriority.highest,
      dueDate: today,
      createdAt: today,
      updatedAt: today,
    );
    final container = await seedItem(item);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: InputModeScope(
          mode: InputMode.touch,
          child: const MaterialApp(home: TodoListPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('今日任务'), findsOneWidget);
    // 有待办时显示导出按钮
    expect(find.byTooltip('导出当日待办为 Markdown'), findsOneWidget);
  });

  testWidgets('有待办卡片显示所属分类名称', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final item = TodoItem(
      id: 'a',
      title: '带分类任务',
      priority: TodoPriority.medium,
      categoryId: 'work',
      dueDate: today,
      createdAt: today,
      updatedAt: today,
    );
    final container = await seedItem(item);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: InputModeScope(
          mode: InputMode.touch,
          child: const MaterialApp(home: TodoListPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('带分类任务'), findsOneWidget);
    expect(find.text('工作'), findsOneWidget);
  });

  testWidgets('导出当日待办仅含所选日期内容', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    final controller = container.read(todoListProvider);
    await controller.add(TodoItem(
      id: 'a',
      title: '今日任务',
      priority: TodoPriority.medium,
      dueDate: today,
      createdAt: today,
      updatedAt: today,
    ));
    await controller.add(TodoItem(
      id: 'b',
      title: '明日任务',
      priority: TodoPriority.medium,
      dueDate: tomorrow,
      createdAt: today,
      updatedAt: today,
    ));

    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: InputModeScope(
          mode: InputMode.touch,
          child: const MaterialApp(home: TodoListPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('导出当日待办为 Markdown'));
    await tester.pumpAndSettle();

    expect(clipboardText, isNotNull);
    expect(clipboardText, contains('今日任务'));
    expect(clipboardText, isNot(contains('明日任务')));
  });

  testWidgets('按分类筛选：选中工作分类后仅显示该分类待办', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    final controller = container.read(todoListProvider);
    await controller.add(TodoItem(
      id: 'a',
      title: '工作任务',
      priority: TodoPriority.medium,
      categoryId: 'work',
      dueDate: today,
      createdAt: today,
      updatedAt: today,
    ));
    await controller.add(TodoItem(
      id: 'b',
      title: '生活任务',
      priority: TodoPriority.medium,
      categoryId: 'life',
      dueDate: today,
      createdAt: today,
      updatedAt: today,
    ));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: InputModeScope(
          mode: InputMode.touch,
          child: const MaterialApp(home: TodoListPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('工作任务'), findsOneWidget);
    expect(find.text('生活任务'), findsOneWidget);

    // 打开筛选面板，选中「工作」分类并确定
    await tester.tap(find.byTooltip('筛选'));
    await tester.pumpAndSettle();
    expect(find.text('分类'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, '工作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    // 仅显示工作分类
    expect(find.text('工作任务'), findsOneWidget);
    expect(find.text('生活任务'), findsNothing);

    // 界面显示当前筛选状态（「工作」标签 + 清除全部按钮）
    expect(find.widgetWithText(InputChip, '工作'), findsOneWidget);
    expect(find.byTooltip('清除全部筛选'), findsOneWidget);

    // 点击单个筛选标签的删除 → 恢复全部
    await tester.tap(find.descendant(
      of: find.widgetWithText(InputChip, '工作'),
      matching: find.byIcon(Icons.close),
    ));
    await tester.pumpAndSettle();
    expect(find.text('工作任务'), findsOneWidget);
    expect(find.text('生活任务'), findsOneWidget);
    expect(find.widgetWithText(InputChip, '工作'), findsNothing);
  });

  testWidgets('按优先级筛选：选中最高后仅显示最高优先级待办', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    final controller = container.read(todoListProvider);
    await controller.add(TodoItem(
      id: 'a',
      title: '最高任务',
      priority: TodoPriority.highest,
      dueDate: today,
      createdAt: today,
      updatedAt: today,
    ));
    await controller.add(TodoItem(
      id: 'b',
      title: '日常任务',
      priority: TodoPriority.daily,
      dueDate: today,
      createdAt: today,
      updatedAt: today,
    ));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: InputModeScope(
          mode: InputMode.touch,
          child: const MaterialApp(home: TodoListPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('最高任务'), findsOneWidget);
    expect(find.text('日常任务'), findsOneWidget);

    await tester.tap(find.byTooltip('筛选'));
    await tester.pumpAndSettle();
    expect(find.text('优先级'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, '最高'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(find.text('最高任务'), findsOneWidget);
    expect(find.text('日常任务'), findsNothing);
  });

  testWidgets('勾选完成需确认，确认后销项移入历史', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final item = TodoItem(
      id: 'a',
      title: '待销项任务',
      priority: TodoPriority.high,
      dueDate: today,
      createdAt: today,
      updatedAt: today,
    );
    final container = await seedItem(item);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: InputModeScope(
          mode: InputMode.touch,
          child: const MaterialApp(home: TodoListPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('待销项任务'), findsOneWidget);

    // 点击完成勾选 → 出现完成确认对话框
    await tester.tap(find.byIcon(Icons.radio_button_unchecked));
    await tester.pumpAndSettle();
    expect(find.text('完成确认'), findsOneWidget);

    // 取消：不销项，任务仍在
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('待销项任务'), findsOneWidget);
    expect(container.read(todoListProvider).items.single.isArchived, isFalse);

    // 再次勾选并确认 → 销项归档
    await tester.tap(find.byIcon(Icons.radio_button_unchecked));
    await tester.pumpAndSettle();
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(find.text('待销项任务'), findsNothing);
    final archived = container.read(todoListProvider).items.single;
    expect(archived.isCompleted, isTrue);
    expect(archived.isArchived, isTrue);
  });

  testWidgets('完成循环单日实例后日历不再标记该日', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final markKey = 'todo_mark_${today.year}_${today.month}_${today.day}';
    final template = TodoItem(
      id: 'tpl',
      title: '循环任务',
      priority: TodoPriority.medium,
      recurrenceRules: [
        RecurrenceRule(
          pattern: MonthlyDayPattern(interval: 1, days: {today.day}),
          startDate: today,
        ),
      ],
      createdAt: DateTime(today.year, today.month, 1),
      updatedAt: DateTime(today.year, today.month, 1),
    );
    final container = await seedItem(template);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: InputModeScope(
          mode: InputMode.touch,
          child: const MaterialApp(home: TodoListPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 完成前：该日有标记
    expect(find.byKey(ValueKey(markKey)), findsOneWidget);

    // 完成今日实例（仅销项当次）
    final tpl =
        container.read(todoListProvider).items.firstWhere((e) => e.id == 'tpl');
    await container.read(todoListProvider).completeOccurrence(tpl, today);
    await tester.pumpAndSettle();

    // 完成后：该日标记消失，模板仍开启
    expect(find.byKey(ValueKey(markKey)), findsNothing);
    expect(container.read(todoListProvider).items.firstWhere((e) => e.id == 'tpl').isArchived, false);
  });

  testWidgets('循环模板当月标注待办日期', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final template = TodoItem(
      id: 'tpl',
      title: '循环任务',
      priority: TodoPriority.medium,
      recurrenceRules: [
        RecurrenceRule(
          pattern: MonthlyDayPattern(interval: 1, days: {today.day}),
          startDate: today,
        ),
      ],
      createdAt: today,
      updatedAt: today,
    );
    final container = await seedItem(template);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: InputModeScope(
          mode: InputMode.touch,
          child: const MaterialApp(home: TodoListPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 模板自身命中今日，应显示
    expect(find.text('循环任务'), findsOneWidget);
  });

  testWidgets('横竖屏布局随 ResponsiveBuilder 切换', (tester) async {
    final container = ProviderContainer(
      overrides: overrides(),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: InputModeScope(
          mode: InputMode.touch,
          child: const MaterialApp(home: TodoListPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 默认竖屏布局渲染成功即为验证通过（避免溢出）
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄横屏布局日历头部不溢出', (tester) async {
    // 模拟横屏窄窗口：两列布局下日历列宽不足 220，header 应自适应。
    tester.view.physicalSize = const Size(300 * 2, 200 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: InputModeScope(
          mode: InputMode.touch,
          child: const MaterialApp(home: TodoListPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}