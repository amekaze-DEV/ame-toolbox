import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/unit_converter_service.dart';
import 'calculator_config_provider.dart';
import 'unit_converter_controller.dart';

/// 注入 [UnitConverterService]。
final unitConverterServiceProvider = Provider<UnitConverterService>(
  (ref) => UnitConverterService(),
);

/// 注入 [UnitConverterController]。
final unitConverterProvider = ChangeNotifierProvider<UnitConverterController>(
  (ref) {
    final service = ref.watch(unitConverterServiceProvider);
    final configController = ref.read(calculatorConfigProvider);
    return UnitConverterController(
      service: service,
      configController: configController,
    );
  },
);
