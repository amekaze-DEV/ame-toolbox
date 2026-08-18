import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'todo_config_provider.dart';
import 'todo_list_controller.dart';
import 'todo_list_repository_provider.dart';
import 'todo_reminder_service_provider.dart';
import 'todo_recurrence_resolver_provider.dart';

/// 待办列表状态控制器。
///
/// 依赖配置控制器（用于提醒开关）、提醒服务与多规则解析器。
/// 创建后自动从持久化存储加载待办列表，确保页面首帧即展示已存数据。
final todoListProvider = ChangeNotifierProvider<TodoListController>((ref) {
  final repository = ref.watch(todoListRepositoryProvider);
  final resolver = ref.watch(todoRecurrenceResolverProvider);
  final reminderService = ref.watch(todoReminderServiceProvider);
  // 使用 ref.read 避免 config 变更时重建整个控制器（导致 items 丢失）。
  final configController = ref.read(todoConfigProvider);
  final controller = TodoListController(
    repository: repository,
    resolver: resolver,
    reminderService: reminderService,
    configController: configController,
  );
  unawaited(controller.load());
  return controller;
});