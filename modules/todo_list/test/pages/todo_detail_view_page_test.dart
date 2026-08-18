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
import 'package:todo_list_module/features/todo_list/models/recurrence_pattern.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_rule.dart';
import 'package:todo_list_module/features/todo_list/models/todo_item.dart';
import 'package:todo_list_module/features/todo_list/models/todo_priority.dart';
import 'package:todo_list_module/features/todo_list/pages/todo_detail_view_page.dart';

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

  Widget wrap(Widget child) => InputModeScope(
        mode: InputMode.touch,
        child: ProviderScope(overrides: overrides(), child: child),
      );

  TodoItem makeItem({
    String title = '待办标题',
    String? details,
    TodoPriority priority = TodoPriority.high,
    DateTime? dueDate,
    List<RecurrenceRule> rules = const [],
    String? categoryId,
  }) {
    final now = DateTime.now();
    return TodoItem(
      id: 'v1',
      title: title,
      details: details,
      categoryId: categoryId,
      priority: priority,
      dueDate: dueDate,
      recurrenceRules: rules,
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets('查看页展示名称、优先级、详情与编辑按钮', (tester) async {
    await tester.pumpWidget(
      wrap(MaterialApp(
        home: TodoDetailViewPage(
          item: makeItem(details: '这是详情内容', priority: TodoPriority.highest),
        ),
      )),
    );
    expect(find.text('待办标题'), findsWidgets); // AppBar 标题
    expect(find.text('最高'), findsOneWidget); // 优先级
    expect(find.text('这是详情内容'), findsOneWidget);
    expect(find.text('编辑'), findsOneWidget);
    // 提供导出该条待办的按钮
    expect(find.byTooltip('导出该待办为 Markdown'), findsOneWidget);
  });

  testWidgets('导出按钮仅复制该条待办内容', (tester) async {
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
      wrap(MaterialApp(
        home: TodoDetailViewPage(item: makeItem(title: '唯一待办')),
      )),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('导出该待办为 Markdown'));
    await tester.pumpAndSettle();

    expect(clipboardText, isNotNull);
    expect(clipboardText, contains('唯一待办'));
  });

  testWidgets('查看页无详情时显示暂无详情', (tester) async {
    await tester.pumpWidget(
      wrap(MaterialApp(home: TodoDetailViewPage(item: makeItem()))),
    );
    expect(find.text('暂无详情'), findsOneWidget);
  });

  testWidgets('查看页展示循环规则描述与无限循环', (tester) async {
    final now = DateTime.now();
    final rule = RecurrenceRule(
      pattern: WeeklyPattern(interval: 1, weekdays: {1, 4}),
      startDate: DateTime(now.year, now.month, now.day),
    );
    await tester.pumpWidget(
      wrap(MaterialApp(
        home: TodoDetailViewPage(item: makeItem(rules: [rule])),
      )),
    );
    expect(find.text('每1周，周一、周四'), findsOneWidget);
    expect(find.textContaining('无限循环'), findsOneWidget);
  });

  testWidgets('一次性事项展示期限', (tester) async {
    final due = DateTime(2026, 8, 20);
    await tester.pumpWidget(
      wrap(MaterialApp(
        home: TodoDetailViewPage(item: makeItem(dueDate: due)),
      )),
    );
    expect(find.text('2026-08-20'), findsOneWidget);
  });
}