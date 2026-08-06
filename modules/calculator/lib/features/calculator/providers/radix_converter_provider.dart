import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/radix_converter_service.dart';
import 'calculator_config_provider.dart';
import 'radix_converter_controller.dart';

/// 注入 [RadixConverterService]。
final radixConverterServiceProvider = Provider<RadixConverterService>(
  (ref) => RadixConverterService(),
);

/// 注入 [RadixConverterController]。
final radixConverterProvider = ChangeNotifierProvider<RadixConverterController>(
  (ref) {
    final service = ref.watch(radixConverterServiceProvider);
    final configController = ref.read(calculatorConfigProvider);
    return RadixConverterController(
      service: service,
      configController: configController,
    );
  },
);
