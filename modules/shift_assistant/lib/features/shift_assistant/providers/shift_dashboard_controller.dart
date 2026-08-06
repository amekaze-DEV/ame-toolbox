import 'package:flutter/material.dart';

import '../models/day_info.dart';
import '../services/lunar_info_service.dart';
import '../services/shift_schedule_service.dart';
import '../utils/date_utils.dart';
import 'holiday_data_controller.dart';
import 'shift_config_controller.dart';

/// 首页仪表盘状态控制器。
///
/// 聚合当天（或用户选中的）日期信息，包括农历、节假日及各班组班次。
/// 状态变更后通过 [notifyListeners] 通知 UI 重建。
class ShiftDashboardController extends ChangeNotifier {
  ShiftDashboardController({
    required this.configController,
    required this.holidayController,
    required this.lunarService,
    required this.scheduleService,
    DateTime? selectedDate,
  }) : _selectedDate = dateOnly(selectedDate ?? DateTime.now());

  final ShiftConfigController configController;
  final HolidayDataController holidayController;
  final LunarInfoService lunarService;
  final ShiftScheduleService scheduleService;

  DateTime _selectedDate;

  /// 当前选中的日期。
  DateTime get selectedDate => _selectedDate;

  /// 当前选中日期的聚合信息。
  DayInfo get dayInfo {
    final rotation = configController.config.primaryRotation;
    final lunarDate = lunarService.getLunarDate(_selectedDate);
    final solarTerm = lunarService.getSolarTerm(_selectedDate);
    final holiday = holidayController.getHoliday(_selectedDate);

    if (rotation == null) {
      return DayInfo(
        date: _selectedDate,
        lunarDate: lunarDate,
        solarTerm: solarTerm,
        holiday: holiday,
      );
    }

    return scheduleService.buildDayInfo(
      rotation,
      _selectedDate,
      lunarDate: lunarDate,
      solarTerm: solarTerm,
      holiday: holiday,
    );
  }

  /// 选中指定日期。
  void selectDate(DateTime date) {
    final normalized = dateOnly(date);
    if (isSameDay(normalized, _selectedDate)) return;
    _selectedDate = normalized;
    notifyListeners();
  }

  /// 跳转到今天。
  void goToToday() {
    selectDate(DateTime.now());
  }
}
