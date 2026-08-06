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
/// 模块初始化时需调用 [CalculatorConfigController.load()] 从仓库加载 persisted 配置。
final calculatorConfigProvider = ChangeNotifierProvider<CalculatorConfigController>(
  (ref) {
    final repository = ref.watch(calculatorConfigRepositoryProvider);
    return CalculatorConfigController(repository: repository);
  },
);
