import '../models/day_info.dart';
import '../models/shift_config.dart';
import '../utils/date_utils.dart';

/// 排班计算服务。
///
/// 纯函数服务，根据轮班基准日期与周期分配矩阵计算任意日期对应的班组状态，
/// 并聚合生成 [DayInfo]。
class ShiftScheduleService {
  /// 计算 [rotation] 在 [date] 当天各班组的状态。
  ///
  /// [date] 与 [rotation.baseDate] 在计算前会被规范为日期部分（忽略时间）。
  Map<String, ShiftSlot> calculateShiftsForDate(
    ShiftRotation rotation,
    DateTime date,
  ) {
    final normalizedDate = dateOnly(date);
    final normalizedBase = dateOnly(rotation.baseDate);
    final offset = normalizedDate.difference(normalizedBase).inDays;
    final cycleDays = rotation.cycleDays;
    var dayIndex = offset % cycleDays;
    if (dayIndex < 0) dayIndex += cycleDays;

    final result = <String, ShiftSlot>{};
    for (var groupIndex = 0; groupIndex < rotation.groups.length; groupIndex++) {
      final group = rotation.groups[groupIndex];
      final slot = rotation.slotFor(groupIndex, dayIndex);
      result[group.id] = slot;
    }
    return result;
  }

  /// 为 [date] 聚合指定轮班的 [DayInfo]。
  ///
  /// [lunarDate]、[solarTerm]、[holiday] 由 [LunarInfoService] 与
  /// [HolidayDataController] 提供；未传入时保持为空。
  DayInfo buildDayInfo(
    ShiftRotation rotation,
    DateTime date, {
    String lunarDate = '',
    String? solarTerm,
    HolidayInfo? holiday,
  }) {
    final normalized = dateOnly(date);
    final shifts = calculateShiftsForDate(rotation, normalized);

    return DayInfo(
      date: normalized,
      lunarDate: lunarDate,
      solarTerm: solarTerm,
      holiday: holiday,
      rotationId: rotation.id,
      groupShifts: shifts,
    );
  }

  /// 为 [date] 所在周的 7 天聚合 [DayInfo] 列表。
  List<DayInfo> buildWeekDayInfo(
    ShiftRotation rotation,
    DateTime date,
  ) {
    return daysOfWeek(date)
        .map((d) => buildDayInfo(rotation, d))
        .toList();
  }

  /// 获取轮班中所有状态的唯一名称列表，按首次出现顺序排列。
  ///
  /// 结果用于月历视图左侧的状态行标签。
  List<String> slotNames(ShiftRotation rotation) {
    return rotation.slots.map((s) => s.name).toList();
  }

  /// 获取 [dayInfo] 中状态名称为 [slotName] 的所有班组。
  ///
  /// 返回顺序与 [rotation.groups] 一致。
  List<ShiftGroup> groupsWithSlot(
    DayInfo dayInfo,
    String slotName,
    ShiftRotation rotation,
  ) {
    final result = <ShiftGroup>[];
    for (final group in rotation.groups) {
      final slot = dayInfo.shiftForGroup(group.id);
      if (slot != null && slot.name == slotName) {
        result.add(group);
      }
    }
    return result;
  }

  /// 为 [date] 所在月的完整周网格聚合 [DayInfo]。
  List<List<DayInfo>> buildMonthDayInfo(
    ShiftRotation rotation,
    DateTime date,
  ) {
    return monthWeeks(date)
        .map((week) => week.map((d) => buildDayInfo(rotation, d)).toList())
        .toList();
  }
}
