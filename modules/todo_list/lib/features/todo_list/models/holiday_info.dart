/// 单天节假日信息。
///
/// 表示某一天的法定节假日或调休安排，数据来自在线节假日源或本地兜底。
/// 独立于倒班助手的同名模型，仅限待办模块内部使用。
class HolidayInfo {
  /// 节假日/调休名称，如“春节”、“劳动节补班”。
  final String name;

  /// 是否为法定节假日（休息日）。
  final bool isHoliday;

  /// 是否为调休上班日。
  final bool isWorkday;

  const HolidayInfo({
    required this.name,
    this.isHoliday = false,
    this.isWorkday = false,
  });

  HolidayInfo copyWith({
    String? name,
    bool? isHoliday,
    bool? isWorkday,
  }) =>
      HolidayInfo(
        name: name ?? this.name,
        isHoliday: isHoliday ?? this.isHoliday,
        isWorkday: isWorkday ?? this.isWorkday,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'isHoliday': isHoliday,
        'isWorkday': isWorkday,
      };

  factory HolidayInfo.fromJson(Map<String, dynamic> json) => HolidayInfo(
        name: json['name'] as String,
        isHoliday: json['isHoliday'] as bool? ?? false,
        isWorkday: json['isWorkday'] as bool? ?? false,
      );
}
