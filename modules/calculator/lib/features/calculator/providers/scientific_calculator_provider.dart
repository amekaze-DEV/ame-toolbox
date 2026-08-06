import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/scientific_calculator_service.dart';
import 'calculator_config_provider.dart';
import 'scientific_calculator_controller.dart';

/// 注入 [ScientificCalculatorService]。
final scientificCalculatorServiceProvider = Provider<ScientificCalculatorService>(
  (ref) => ScientificCalculatorService(),
);

/// 注入 [ScientificCalculatorController]。
///
/// 依赖 [calculatorConfigProvider] 读取配置与写入历史记录。
final scientificCalculatorProvider = ChangeNotifierProvider<ScientificCalculatorController>(
  (ref) {
    final service = ref.watch(scientificCalculatorServiceProvider);
    final configController = ref.read(calculatorConfigProvider);
    return ScientificCalculatorController(
      service: service,
      configController: configController,
    );
  },
);
