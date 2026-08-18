import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/providers/notification_provider.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/debug/fake_device_info.dart';
import 'package:todo_list_module/debug/memory_storage_service.dart';
import 'package:todo_list_module/debug/noop_notification_service.dart';
import 'package:todo_list_module/features/todo_list/pages/todo_list_settings_page.dart';
import 'package:todo_list_module/features/todo_list/providers/todo_config_provider.dart';

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

  Widget wrap(Widget child, {ProviderContainer? container}) {
    final scope = container == null
        ? ProviderScope(overrides: overrides(), child: child)
        : UncontrolledProviderScope(container: container, child: child);
    return InputModeScope(mode: InputMode.touch, child: scope);
  }

  testWidgets('设置页渲染分区标题且不再提供导出', (tester) async {
    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoListSettingsPage())),
    );
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('分类管理'), findsOneWidget);
    expect(find.text('列表显示'), findsOneWidget);
    expect(find.text('全局提醒设置'), findsOneWidget);
    expect(find.text('导出'), findsNothing);
  });

  testWidgets('内置分类展示名称', (tester) async {
    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoListSettingsPage())),
    );
    await tester.pumpAndSettle();
    expect(find.text('工作'), findsWidgets);
    expect(find.text('生活'), findsWidgets);
  });

  testWidgets('提醒开关切换持久化', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoListSettingsPage()), container: container),
    );
    await tester.pumpAndSettle();

    // 通过 key 定位"到期提醒"行内的实际 Switch 并切换
    final remindRow = find.byKey(const ValueKey('remind_enabled_switch'));
    expect(remindRow, findsOneWidget);
    final switchFinder = find.descendant(
      of: remindRow,
      matching: find.byType(Switch),
    );
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    final config = container.read(todoConfigProvider).config;
    expect(config.remindEnabled, isFalse);
  });

  testWidgets('新增分类后出现在列表', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoListSettingsPage()), container: container),
    );
    await tester.pumpAndSettle();

    await container.read(todoConfigProvider).addCategory(
          '个人',
          colorValue: 0xFF00838F,
        );
    await tester.pumpAndSettle();

    expect(find.text('个人'), findsOneWidget);
    expect(container.read(todoConfigProvider).config.categories.length, 4);
  });

  testWidgets('横竖屏布局渲染无异常', (tester) async {
    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoListSettingsPage())),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('自定义默认提前分钟数可保存', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoListSettingsPage()), container: container),
    );
    await tester.pumpAndSettle();

    // 打开下拉菜单并选择「自定义…」
    await tester.tap(find.byType(DropdownMenu<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('自定义…').last);
    await tester.pumpAndSettle();

    // 输入自定义分钟数并确定
    expect(find.text('自定义提前分钟数'), findsOneWidget);
    final dialogField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogField, '45');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(container.read(todoConfigProvider).config.defaultRemindMinutes, 45);
    // 关闭弹窗后，下拉框应显示当前自定义值
    expect(find.text('自定义 45 分钟'), findsWidgets);
  });

  testWidgets('自定义分钟数非法输入不保存', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoListSettingsPage()), container: container),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownMenu<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('自定义…').last);
    await tester.pumpAndSettle();

    final dialogField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogField, '0');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    // 输入非法时对话框不关闭，配置保持不变
    expect(find.text('自定义提前分钟数'), findsOneWidget);
    expect(container.read(todoConfigProvider).config.defaultRemindMinutes, 30);
  });
}