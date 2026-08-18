import 'dart:async';

import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/todo_config_repository.dart';
import 'todo_config_controller.dart';

/// 注入配置 Repository。
final todoConfigRepositoryProvider = Provider<TodoConfigRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return TodoConfigRepository(storageService: storage);
});

/// 配置状态控制器。
///
/// 创建后自动从持久化存储加载配置，确保日历视图与设置页读取同一实例。
final todoConfigProvider =
    ChangeNotifierProvider<TodoConfigController>((ref) {
  final repository = ref.watch(todoConfigRepositoryProvider);
  final controller = TodoConfigController(repository);
  unawaited(controller.load());
  return controller;
});