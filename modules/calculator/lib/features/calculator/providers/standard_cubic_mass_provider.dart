import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/standard_cubic_mass_service.dart';
import 'calculator_config_provider.dart';
import 'standard_cubic_mass_controller.dart';

/// 注入 [StandardCubicMassService]。
final standardCubicMassServiceProvider = Provider<StandardCubicMassService>(
  (ref) => const StandardCubicMassService(),
);

/// 注入 [StandardCubicMassController]。
final standardCubicMassProvider = ChangeNotifierProvider<StandardCubicMassController>(
  (ref) {
    final service = ref.watch(standardCubicMassServiceProvider);
    final configController = ref.read(calculatorConfigProvider);
    return StandardCubicMassController(
      service: service,
      configController: configController,
    );
  },
);
