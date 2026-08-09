import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';

import '../data/shift_config_repository.dart';
import 'shift_config_controller.dart';

/// 注入 [ShiftConfigRepository]。
///
/// 依赖底座 [storageServiceProvider]，由主项目 [main()] 注入初始化后的实例。
final shiftConfigRepositoryProvider = Provider<ShiftConfigRepository>(
  (ref) {
    final storage = ref.watch(storageServiceProvider);
    return ShiftConfigRepository(storage: storage);
  },
);

/// 倒班助手配置状态。
///
/// 自动从持久化存储加载配置，确保日历视图和设置页读取同一实例。
final shiftConfigProvider = ChangeNotifierProvider<ShiftConfigController>(
  (ref) {
    final repository = ref.watch(shiftConfigRepositoryProvider);
    final controller = ShiftConfigController(repository: repository);
    unawaited(controller.load());
    return controller;
  },
);
