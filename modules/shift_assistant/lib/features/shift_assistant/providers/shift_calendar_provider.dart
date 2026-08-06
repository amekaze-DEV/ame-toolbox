import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shift_calendar_controller.dart';

/// 周历视图状态。
///
/// 管理当前聚焦日期、当前周、选中日期。
final shiftCalendarProvider = ChangeNotifierProvider<ShiftCalendarController>(
  (ref) => ShiftCalendarController(),
);
