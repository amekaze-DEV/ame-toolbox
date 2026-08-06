import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/geometry_service.dart';
import '../services/unit_converter_service.dart';
import 'calculator_config_provider.dart';
import 'geometry_controller.dart';

/// 注入 [GeometryService]。
final geometryServiceProvider = Provider<GeometryService>(
  (ref) => GeometryService(),
);

/// 注入 [UnitConverterService]，供几何模块使用。
final geometryUnitServiceProvider = Provider<UnitConverterService>(
  (ref) => UnitConverterService(),
);

/// 注入 [GeometryController]。
final geometryProvider = ChangeNotifierProvider<GeometryController>(
  (ref) {
    final service = ref.watch(geometryServiceProvider);
    final unitService = ref.watch(geometryUnitServiceProvider);
    final configController = ref.read(calculatorConfigProvider);
    return GeometryController(
      service: service,
      unitService: unitService,
      configController: configController,
    );
  },
);
