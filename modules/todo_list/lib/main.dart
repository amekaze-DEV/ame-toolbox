import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/input/input_detector.dart';
import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/layout/responsive_builder.dart';
import 'package:ametoolbox/core/models/theme_config.dart' as app_theme;
import 'package:ametoolbox/core/providers/input_provider.dart';
import 'package:ametoolbox/core/providers/layout_provider.dart';
import 'package:ametoolbox/core/providers/notification_provider.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:ametoolbox/core/providers/theme_provider.dart';
import 'package:ametoolbox/core/theme/md3_color_scheme.dart';

import 'debug/fake_device_info.dart';
import 'debug/memory_storage_service.dart';
import 'debug/noop_notification_service.dart';
import 'features/todo_list/models/recurrence_pattern.dart';
import 'features/todo_list/models/recurrence_rule.dart';
import 'features/todo_list/models/todo_item.dart';
import 'features/todo_list/models/todo_priority.dart';
import 'features/todo_list/todo_list_module.dart';

/// 临时调试外壳底部导航索引。
final _debugShellIndexProvider = StateProvider<int>((ref) => 0);

void main() {
  final memoryStorage = MemoryStorageService();
  final fakeDeviceInfo = FakeDeviceInfoProvider();
  final noopNotification = NoopNotificationService();

  // 调试：向内存存储写入示例数据，启动即有内容可验证 UI。
  _bootstrapSampleData(memoryStorage);

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(memoryStorage),
        deviceInfoProvider.overrideWithValue(fakeDeviceInfo),
        notificationServiceProvider.overrideWithValue(noopNotification),
      ],
      child: const TodoListDebugApp(),
    ),
  );
}

/// 写入示例待办数据（一次性 / 过期 / 每周循环 / 每月循环）。
Future<void> _bootstrapSampleData(MemoryStorageService storage) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final items = [
    // 一次性待办（今天）
    TodoItem(
      id: 'todo_1',
      title: '完成项目文档',
      details: '补充 API 文档和使用说明',
      priority: TodoPriority.highest,
      dueDate: today,
      createdAt: today,
      updatedAt: today,
    ),
    // 一次性待办（昨天，已过期）
    TodoItem(
      id: 'todo_2',
      title: '购买办公用品',
      priority: TodoPriority.high,
      dueDate: yesterday,
      createdAt: yesterday,
      updatedAt: yesterday,
    ),
    // 循环待办（每周周一、周四）
    TodoItem(
      id: 'todo_3',
      title: '周会',
      priority: TodoPriority.medium,
      recurrenceRules: [
        RecurrenceRule(
          pattern: const WeeklyPattern(interval: 1, weekdays: {1, 4}),
          startDate: today,
        ),
      ],
      createdAt: today,
      updatedAt: today,
    ),
    // 循环待办（每月 1 日）
    TodoItem(
      id: 'todo_4',
      title: '月度总结',
      priority: TodoPriority.normal,
      recurrenceRules: [
        RecurrenceRule(
          pattern: const MonthlyDayPattern(interval: 1, days: {1}),
          startDate: today,
        ),
      ],
      createdAt: today,
      updatedAt: today,
    ),
  ];

  await storage.saveData('module_todo_list_items', {
    'schemaVersion': 1,
    'items': items.map((e) => e.toJson()).toList(),
  });
}

/// 待办清单模块临时调试外壳。
///
/// 提供双页选项卡（主页面 / 设置页），使用 MD3 主题与底座 ResponsiveBuilder。
class TodoListDebugApp extends ConsumerWidget {
  const TodoListDebugApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = ref.watch(themeControllerProvider);
    final layoutController = ref.watch(layoutControllerProvider);
    final inputController = ref.watch(inputControllerProvider);

    final brightness = themeController.config.mode == app_theme.AppThemeMode.dark
        ? Brightness.dark
        : Brightness.light;
    final colorScheme = Md3ColorScheme.fromAccent(
      themeController.config.accentColorHex,
      brightness,
    );

    return InputDetector(
      controller: inputController,
      child: AnimatedTheme(
        data: ThemeData(
          colorScheme: colorScheme,
          useMaterial3: true,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: MaterialApp(
          title: '待办清单 - 调试',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: colorScheme,
            useMaterial3: true,
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  layoutController.effectiveDpiScale *
                      themeController.config.fontScale,
                ),
              ),
              child: child!,
            );
          },
          home: const DebugShell(),
        ),
      ),
    );
  }
}

/// 双页调试外壳。
///
/// 底部选项卡切换主页面与设置页，页面内使用 ResponsiveBuilder 适配横竖屏。
class DebugShell extends ConsumerWidget {
  const DebugShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(_debugShellIndexProvider);
    final todoListModule = TodoListModule();

    final pages = <Widget>[
      ResponsiveBuilder(
        portraitBuilder: (_) => _DebugPageWrapper(
          child: todoListModule.buildPage(context, ref),
        ),
        landscapeBuilder: (_) => _DebugPageWrapper(
          child: todoListModule.buildPage(context, ref),
        ),
      ),
      ResponsiveBuilder(
        portraitBuilder: (_) => _DebugPageWrapper(
          child: todoListModule.buildSettingsPage(context, ref) ??
              const SizedBox.shrink(),
        ),
        landscapeBuilder: (_) => _DebugPageWrapper(
          child: todoListModule.buildSettingsPage(context, ref) ??
              const SizedBox.shrink(),
        ),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(_debugShellIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: '主页面',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置页',
          ),
        ],
      ),
    );
  }
}

/// 调试页面通用包装器，提供输入模式上下文。
class _DebugPageWrapper extends ConsumerWidget {
  const _DebugPageWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputMode = ref.watch(inputControllerProvider).currentMode;
    return InputModeScope(
      mode: inputMode,
      child: child,
    );
  }
}