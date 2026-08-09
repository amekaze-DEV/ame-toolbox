import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';

import '../data/calculator_config_repository.dart';
import 'calculator_config_controller.dart';

/// 注入 [CalculatorConfigRepository]。
///
/// 依赖底座 [storageServiceProvider]，由主项目 [main()] 注入初始化后的实例。
final calculatorConfigRepositoryProvider = Provider<CalculatorConfigRepository>(
  (ref) {
    final storage = ref.watch(storageServiceProvider);
    return CalculatorConfigRepository(storage: storage);
  },
);

/// 注入 [CalculatorConfigController]。
///
/// 自动从 Hive 加载持久化配置，确保仪表盘卡片和设置页读取同一实例。
final calculatorConfigProvider = ChangeNotifierProvider<CalculatorConfigController>(
  (ref) {
    final repository = ref.watch(calculatorConfigRepositoryProvider);
    final controller = CalculatorConfigController(repository: repository);
    // 异步加载持久化配置，加载完成后通知监听者
    unawaited(controller.load());
    return controller;
  },
);
