import 'shift_config.dart';

/// 某日期聚合信息（运行时模型，不持久化）。
///
/// 包含公历日期、农历/节气/节假日信息，以及当天各班组对应的班次。
class DayInfo {
  /// 公历日期（日期部分，时间恒为 00:00:00）。
  final DateTime date;

  /// 农历日期字符串，如“七月初一”。
  ///
  /// 在 [LunarInfoService] 实现前可留空，由 UI 层判断是否显示。
  final String lunarDate;

  /// 节气，如“立秋”。为 null 表示当日无节气。
  final String? solarTerm;

  /// 公历节日列表，如“国庆节”、“教师节”、“母亲节”。空列表表示当日无节日。
  final List<String> solarFestivals;

  /// 节假日/调休信息。为 null 表示当日无特殊节假日。
  final HolidayInfo? holiday;

  /// 当前轮班 ID；用于区分不同轮班的排班数据。
  final String? rotationId;

  /// 各班组在当天的班次，key 为班组 ID。
  final Map<String, ShiftSlot> groupShifts;

  const DayInfo({
    required this.date,
    this.lunarDate = '',
    this.solarTerm,
    this.solarFestivals = const [],
    this.holiday,
    this.rotationId,
    this.groupShifts = const {},
  });

  /// 获取指定班组的班次；找不到时返回 null。
  ShiftSlot? shiftForGroup(String groupId) => groupShifts[groupId];

  DayInfo copyWith({
    DateTime? date,
    String? lunarDate,
    String? solarTerm,
    List<String>? solarFestivals,
    HolidayInfo? holiday,
    String? rotationId,
    Map<String, ShiftSlot>? groupShifts,
  }) =>
      DayInfo(
        date: date ?? this.date,
        lunarDate: lunarDate ?? this.lunarDate,
        solarTerm: solarTerm ?? this.solarTerm,
        solarFestivals: solarFestivals ?? this.solarFestivals,
        holiday: holiday ?? this.holiday,
        rotationId: rotationId ?? this.rotationId,
        groupShifts: groupShifts ?? this.groupShifts,
      );
}
