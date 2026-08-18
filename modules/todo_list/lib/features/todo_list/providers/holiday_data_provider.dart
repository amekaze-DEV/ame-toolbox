import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/holiday_data_service.dart';
import 'holiday_data_controller.dart';
import 'todo_config_provider.dart';

/// 注入 [HolidayDataService]。
final holidayDataServiceProvider = Provider<HolidayDataService>((ref) {
  return HolidayDataService();
});

/// 节假日数据状态。
///
/// 管理节假日缓存、更新状态及多源拉取降级。
final holidayDataProvider = ChangeNotifierProvider<HolidayDataController>(
  (ref) {
    final service = ref.watch(holidayDataServiceProvider);
    final configController = ref.watch(todoConfigProvider);
    return HolidayDataController(
      service: service,
      configController: configController,
    );
  },
);
