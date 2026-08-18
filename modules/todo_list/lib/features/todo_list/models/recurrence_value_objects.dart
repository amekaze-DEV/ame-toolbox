// ──────────────────────────────────────────────
// 循环周期值对象
// ──────────────────────────────────────────────
// 这些值对象用于 [RecurrencePattern] 各子类中表达
// "第几周 + 周几"、"第几个月 + 几号" 等组合参数。
// ──────────────────────────────────────────────

/// 第几周 + 周几。
class WeekDay {
  const WeekDay({required this.week, required this.weekday});

  /// 第几周（1 ~ 5）。
  final int week;

  /// 周几（1=周一 ~ 7=周日）。
  final int weekday;

  Map<String, dynamic> toJson() => {'week': week, 'weekday': weekday};

  factory WeekDay.fromJson(Map<String, dynamic> json) => WeekDay(
        week: json['week'] as int,
        weekday: json['weekday'] as int,
      );
}

/// 季度内第几个月 + 几号。
class MonthInQuarterDay {
  const MonthInQuarterDay({required this.monthInQuarter, required this.day});

  /// 1 ~ 3。
  final int monthInQuarter;

  /// 1 ~ 31。
  final int day;

  Map<String, dynamic> toJson() =>
      {'monthInQuarter': monthInQuarter, 'day': day};

  factory MonthInQuarterDay.fromJson(Map<String, dynamic> json) =>
      MonthInQuarterDay(
        monthInQuarter: json['monthInQuarter'] as int,
        day: json['day'] as int,
      );
}

/// 季度内第几个月 + 第几周 + 周几。
class MonthInQuarterWeekDay {
  const MonthInQuarterWeekDay({
    required this.monthInQuarter,
    required this.week,
    required this.weekday,
  });

  /// 1 ~ 3。
  final int monthInQuarter;

  /// 1 ~ 5。
  final int week;

  /// 1 ~ 7。
  final int weekday;

  Map<String, dynamic> toJson() => {
        'monthInQuarter': monthInQuarter,
        'week': week,
        'weekday': weekday,
      };

  factory MonthInQuarterWeekDay.fromJson(Map<String, dynamic> json) =>
      MonthInQuarterWeekDay(
        monthInQuarter: json['monthInQuarter'] as int,
        week: json['week'] as int,
        weekday: json['weekday'] as int,
      );
}

/// 第几个月 + 几号。
class MonthDay {
  const MonthDay({required this.month, required this.day});

  /// 1 ~ 12。
  final int month;

  /// 1 ~ 31。
  final int day;

  Map<String, dynamic> toJson() => {'month': month, 'day': day};

  factory MonthDay.fromJson(Map<String, dynamic> json) => MonthDay(
        month: json['month'] as int,
        day: json['day'] as int,
      );
}

/// 第几个月 + 第几周 + 周几。
class MonthWeekDay {
  const MonthWeekDay({
    required this.month,
    required this.week,
    required this.weekday,
  });

  /// 1 ~ 12。
  final int month;

  /// 1 ~ 5。
  final int week;

  /// 1 ~ 7。
  final int weekday;

  Map<String, dynamic> toJson() => {
        'month': month,
        'week': week,
        'weekday': weekday,
      };

  factory MonthWeekDay.fromJson(Map<String, dynamic> json) => MonthWeekDay(
        month: json['month'] as int,
        week: json['week'] as int,
        weekday: json['weekday'] as int,
      );
}

/// 第几个季度 + 第几天。
class QuarterDay {
  const QuarterDay({required this.quarter, required this.day});

  /// 1 ~ 4。
  final int quarter;

  /// 1 ~ 90+。
  final int day;

  Map<String, dynamic> toJson() => {'quarter': quarter, 'day': day};

  factory QuarterDay.fromJson(Map<String, dynamic> json) => QuarterDay(
        quarter: json['quarter'] as int,
        day: json['day'] as int,
      );
}

/// 第几个季度 + 第几个月 + 几号。
class YearQuarterMonthDay {
  const YearQuarterMonthDay({
    required this.quarter,
    required this.monthInQuarter,
    required this.day,
  });

  /// 1 ~ 4。
  final int quarter;

  /// 1 ~ 3。
  final int monthInQuarter;

  /// 1 ~ 31。
  final int day;

  Map<String, dynamic> toJson() => {
        'quarter': quarter,
        'monthInQuarter': monthInQuarter,
        'day': day,
      };

  factory YearQuarterMonthDay.fromJson(Map<String, dynamic> json) =>
      YearQuarterMonthDay(
        quarter: json['quarter'] as int,
        monthInQuarter: json['monthInQuarter'] as int,
        day: json['day'] as int,
      );
}

/// 第几个季度 + 第几周 + 周几。
class QuarterWeekDay {
  const QuarterWeekDay({
    required this.quarter,
    required this.week,
    required this.weekday,
  });

  /// 1 ~ 4。
  final int quarter;

  /// 1 ~ 5。
  final int week;

  /// 1 ~ 7。
  final int weekday;

  Map<String, dynamic> toJson() => {
        'quarter': quarter,
        'week': week,
        'weekday': weekday,
      };

  factory QuarterWeekDay.fromJson(Map<String, dynamic> json) => QuarterWeekDay(
        quarter: json['quarter'] as int,
        week: json['week'] as int,
        weekday: json['weekday'] as int,
      );
}

/// 第几个季度 + 第几个月 + 第几周 + 周几。
class YearQuarterMonthWeekDay {
  const YearQuarterMonthWeekDay({
    required this.quarter,
    required this.monthInQuarter,
    required this.week,
    required this.weekday,
  });

  /// 1 ~ 4。
  final int quarter;

  /// 1 ~ 3。
  final int monthInQuarter;

  /// 1 ~ 5。
  final int week;

  /// 1 ~ 7。
  final int weekday;

  Map<String, dynamic> toJson() => {
        'quarter': quarter,
        'monthInQuarter': monthInQuarter,
        'week': week,
        'weekday': weekday,
      };

  factory YearQuarterMonthWeekDay.fromJson(Map<String, dynamic> json) =>
      YearQuarterMonthWeekDay(
        quarter: json['quarter'] as int,
        monthInQuarter: json['monthInQuarter'] as int,
        week: json['week'] as int,
        weekday: json['weekday'] as int,
      );
}