import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/lunar_info_service.dart';
import '../services/shift_schedule_service.dart';
import 'holiday_data_controller.dart';
import 'holiday_data_provider.dart';
import 'shift_config_controller.dart';
import 'shift_config_provider.dart';
import 'shift_dashboard_controller.dart';
import 'lunar_info_provider.dart';
import 'shift_schedule_provider.dart';

/// 注入 [ShiftDashboardController]。
///
/// 依赖 [ShiftConfigController]、[HolidayDataController]、
/// [LunarInfoService] 与 [ShiftScheduleService]，并在配置/节假日数据
/// 变化时自动重建。
final shiftDashboardProvider = ChangeNotifierProvider<ShiftDashboardController>(
  (ref) {
    return ShiftDashboardController(
      configController: ref.watch(shiftConfigProvider),
      holidayController: ref.watch(holidayDataProvider),
      lunarService: ref.watch(lunarInfoServiceProvider),
      scheduleService: ref.watch(shiftScheduleProvider),
    );
  },
);
