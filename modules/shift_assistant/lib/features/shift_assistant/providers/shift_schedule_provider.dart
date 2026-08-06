import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/shift_schedule_service.dart';

/// 注入 [ShiftScheduleService] 纯函数服务。
final shiftScheduleProvider = Provider<ShiftScheduleService>((ref) {
  return ShiftScheduleService();
});
