import 'dart:convert';
import 'dart:typed_data';

import 'package:ametoolbox/core/files/file_picker_service.dart';
import 'package:ametoolbox/core/files/picked_file.dart';
import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/providers/file_provider.dart';
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
import 'package:todo_list_module/features/todo_list/pages/todo_detail_page.dart';
import 'package:todo_list_module/features/todo_list/providers/todo_list_provider.dart';

/// 测试用假文件选择服务：返回预设结果并记录调用次数。
class _FakeFilePicker implements FilePickerService {
  _FakeFilePicker(this.results);

  final List<PickedFile> results;
  int pickImagesCallCount = 0;

  @override
  Future<PickedFile?> pickImage({List<String>? allowedExtensions}) async =>
      results.isEmpty ? null : results.first;

  @override
  Future<List<PickedFile>> pickImages({List<String>? allowedExtensions}) async {
    pickImagesCallCount++;
    return results;
  }

  @override
  Future<PickedFile?> pickFile({List<String>? allowedExtensions}) async =>
      results.isEmpty ? null : results.first;
}

/// 1×1 红色 PNG，用于验证附件字节往返。
final Uint8List _demoPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
  'AAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

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

  testWidgets('详情页渲染名称输入框与保存按钮', (tester) async {
    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoDetailPage())),
    );
    expect(find.text('新增待办'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('空名称点击保存提示错误', (tester) async {
    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoDetailPage())),
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('请输入待办名称'), findsOneWidget);
  });

  testWidgets('输入名称保存后新增待办到控制器', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoDetailPage()), container: container),
    );

    await tester.enterText(find.byType(TextField).first, '新增事项');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final controller = container.read(todoListProvider);
    expect(controller.items, hasLength(1));
    expect(controller.items.first.title, '新增事项');
  });

  testWidgets('点击添加图片调用底座选择器并生成 base64 附件', (tester) async {
    final fakePicker = _FakeFilePicker([
      PickedFile(
        name: 'demo.png',
        path: r'C:\demo.png',
        extension: 'png',
        sizeBytes: _demoPngBytes.length,
        readBytes: () async => _demoPngBytes,
      ),
    ]);
    final container = ProviderContainer(
      overrides: [
        ...overrides(),
        filePickerProvider.overrideWithValue(fakePicker),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoDetailPage()), container: container),
    );

    expect(fakePicker.pickImagesCallCount, 0);
    await tester.tap(find.text('添加图片'));
    await tester.pumpAndSettle();
    expect(fakePicker.pickImagesCallCount, 1);

    // 输入名称保存后，附件已写入待办并正确编码。
    await tester.enterText(find.byType(TextField).first, '带图事项');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final controller = container.read(todoListProvider);
    expect(controller.items, hasLength(1));
    expect(controller.items.first.images, hasLength(1));
    expect(
      controller.items.first.images.first.dataBase64,
      base64Encode(_demoPngBytes),
    );
  });

  testWidgets('取消选图不添加任何附件', (tester) async {
    final fakePicker = _FakeFilePicker([]);
    final container = ProviderContainer(
      overrides: [
        ...overrides(),
        filePickerProvider.overrideWithValue(fakePicker),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoDetailPage()), container: container),
    );

    expect(find.text('暂无图片'), findsOneWidget);
    await tester.tap(find.text('添加图片'));
    await tester.pumpAndSettle();
    expect(fakePicker.pickImagesCallCount, 1);
    expect(find.text('暂无图片'), findsOneWidget);
  });

  testWidgets('提醒开关默认开启，关闭后保存写入 remindEnabled', (tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoDetailPage()), container: container),
    );

    // 提醒设置区默认开启，显示执行时刻（默认 09:00）
    expect(find.text('提醒设置'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);

    // 关闭单条提醒开关
    final switchFinder = find.descendant(
      of: find.byKey(const ValueKey('item_remind_switch')),
      matching: find.byType(Switch),
    );
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '关闭提醒事项');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final item = container.read(todoListProvider).items.single;
    expect(item.remindEnabled, false);
  });

  testWidgets('编辑已有待办时预填提醒设置并保存保持不变', (tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    final item = TodoItem(
      id: 'rm',
      title: '提醒事项',
      priority: TodoPriority.medium,
      remindEnabled: true,
      executionTimeMinutes: 14 * 60 + 30, // 14:30
      remindAtExecution: false,
      remindEarly: true,
      remindMinutes: 10,
      createdAt: now,
      updatedAt: now,
    );
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    await container.read(todoListProvider).add(item);

    await tester.pumpWidget(
      wrap(MaterialApp(home: TodoDetailPage(item: item)), container: container),
    );
    await tester.pumpAndSettle();

    expect(find.text('14:30'), findsOneWidget);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final saved = container.read(todoListProvider).items.single;
    expect(saved.executionTimeMinutes, 14 * 60 + 30);
    expect(saved.remindAtExecution, false);
    expect(saved.remindEarly, true);
    expect(saved.remindMinutes, 10);
  });

  testWidgets('新增/编辑页显示分类选择器', (tester) async {
    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoDetailPage())),
    );
    expect(find.text('分类'), findsOneWidget);
    expect(find.byType(DropdownMenu<String?>), findsOneWidget);
  });

  testWidgets('编辑已有分类待办时分类选择器预选当前分类，保存后分类保持不变', (tester) async {
    final now = DateTime.now();
    final item = TodoItem(
      id: 'c1',
      title: '生活事项',
      priority: TodoPriority.medium,
      categoryId: 'life',
      createdAt: now,
      updatedAt: now,
    );
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    await container.read(todoListProvider).add(item);

    await tester.pumpWidget(
      wrap(MaterialApp(home: TodoDetailPage(item: item)), container: container),
    );
    await tester.pumpAndSettle();

    // 下拉框已显示当前分类「生活」
    expect(find.text('生活'), findsWidgets);

    // 直接保存：分类保持不变（保存路径写入表单中的 categoryId）
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(container.read(todoListProvider).items.single.categoryId, 'life');
  });

  testWidgets('编辑模式预填名称并更新', (tester) async {
    final now = DateTime.now();
    final item = TodoItem(
      id: 'edit_1',
      title: '原标题',
      details: '原详情',
      priority: TodoPriority.high,
      dueDate: now,
      createdAt: now,
      updatedAt: now,
    );
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    await container.read(todoListProvider).add(item);

    await tester.pumpWidget(
      wrap(
        MaterialApp(home: TodoDetailPage(item: item)),
        container: container,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('编辑待办'), findsOneWidget);
    expect(find.text('原标题'), findsOneWidget);

    final titleField = find.byType(TextField).first;
    await tester.enterText(titleField, '修改后的标题');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final controller = container.read(todoListProvider);
    expect(controller.items, hasLength(1));
    expect(controller.items.first.title, '修改后的标题');
  });

  testWidgets('新增模式不显示关闭待办', (tester) async {
    await tester.pumpWidget(
      wrap(const MaterialApp(home: TodoDetailPage())),
    );
    expect(find.text('关闭待办'), findsNothing);
    expect(find.text('关闭循环待办'), findsNothing);
  });

  testWidgets('编辑一次性事项显示关闭待办并可关闭归入历史', (tester) async {
    final now = DateTime.now();
    final item = TodoItem(
      id: 'a',
      title: '待关闭',
      priority: TodoPriority.high,
      createdAt: now,
      updatedAt: now,
    );
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    await container.read(todoListProvider).add(item);

    await tester.pumpWidget(
      wrap(MaterialApp(home: TodoDetailPage(item: item)), container: container),
    );
    await tester.pumpAndSettle();

    // 滚动到底部的关闭区
    await tester.scrollUntilVisible(
      find.text('关闭此待办'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('关闭待办'), findsOneWidget); // 区块标题
    await tester.tap(find.text('关闭此待办'));
    await tester.pumpAndSettle();
    expect(find.text('关闭确认'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();

    final archived = container.read(todoListProvider).items.single;
    expect(archived.isCompleted, true);
    expect(archived.isArchived, false);
  });

  testWidgets('编辑循环事项显示关闭循环待办并可整系列关闭', (tester) async {
    final now = DateTime.now();
    final item = TodoItem(
      id: 'tpl',
      title: '循环待办',
      priority: TodoPriority.high,
      recurrenceRules: [
        RecurrenceRule(
          pattern: MonthlyDayPattern(interval: 1, days: {now.day}),
          startDate: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    await container.read(todoListProvider).add(item);

    await tester.pumpWidget(
      wrap(MaterialApp(home: TodoDetailPage(item: item)), container: container),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('关闭循环待办'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('关闭待办'), findsOneWidget); // 区块标题
    await tester.tap(find.text('关闭循环待办'));
    await tester.pumpAndSettle();
    expect(find.text('关闭确认'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();

    // 模板及其实例全部标记完成
    for (final e in container.read(todoListProvider).items) {
      expect(e.isCompleted, true);
    }
  });
}