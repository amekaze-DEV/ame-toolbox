import 'package:ametoolbox/core/providers/notification_provider.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/debug/fake_device_info.dart';
import 'package:todo_list_module/debug/memory_storage_service.dart';
import 'package:todo_list_module/debug/noop_notification_service.dart';
import 'package:todo_list_module/features/todo_list/models/todo_item.dart';
import 'package:todo_list_module/features/todo_list/models/todo_priority.dart';
import 'package:todo_list_module/features/todo_list/providers/todo_config_provider.dart';
import 'package:todo_list_module/features/todo_list/providers/todo_list_provider.dart';
import 'package:todo_list_module/features/todo_list/providers/todo_query_service_provider.dart';

void main() {
  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(MemoryStorageService()),
        deviceInfoProvider.overrideWithValue(FakeDeviceInfoProvider()),
        notificationServiceProvider.overrideWithValue(NoopNotificationService()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('开启日常事项置顶后待办列表不被清空，且日常事项置顶显示', () async {
    final container = buildContainer();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await container.read(todoListProvider).add(
          TodoItem(
            id: 'a',
            title: '日常任务',
            priority: TodoPriority.daily,
            dueDate: today,
            createdAt: today,
            updatedAt: today,
          ),
        );
    await container.read(todoListProvider).add(
          TodoItem(
            id: 'b',
            title: '最高任务',
            priority: TodoPriority.highest,
            dueDate: today,
            createdAt: today,
            updatedAt: today,
          ),
        );
    expect(container.read(todoListProvider).items.length, 2);

    // 与设置页操作一致：开启日常事项置顶
    await container.read(todoConfigProvider).setDailyTop(true);

    // 关键断言：待办列表未被清空
    expect(container.read(todoListProvider).items.length, 2);

    // 排序：日常事项置顶显示
    final query = container.read(todoQueryServiceProvider);
    final sorted = query.sortByPriority(
      container.read(todoListProvider).items,
      dailyTop: container.read(todoConfigProvider).config.dailyTop,
    );
    expect(sorted.map((e) => e.id).toList(), ['a', 'b']);
  });
}
