import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/exchange_rate_service.dart';
import 'calculator_config_provider.dart';
import 'exchange_rate_controller.dart';

/// 注入 [ExchangeRateService]。
final exchangeRateServiceProvider = Provider<ExchangeRateService>(
  (ref) => ExchangeRateService(),
);

/// 注入 [ExchangeRateController]。
final exchangeRateProvider = ChangeNotifierProvider<ExchangeRateController>(
  (ref) {
    final service = ref.watch(exchangeRateServiceProvider);
    final configController = ref.read(calculatorConfigProvider);
    return ExchangeRateController(
      service: service,
      configController: configController,
    );
  },
);
