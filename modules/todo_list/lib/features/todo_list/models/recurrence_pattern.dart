import 'recurrence_value_objects.dart';

// ──────────────────────────────────────────────
// 循环周期策略（sealed class）
// ──────────────────────────────────────────────
// 14 个 final class 与五级菜单一一对应。JSON 序列化使用 type discriminator。
// ──────────────────────────────────────────────

/// 循环周期策略基类。
sealed class RecurrencePattern {
  const RecurrencePattern();

  Map<String, dynamic> toJson();

  /// 从 JSON 反序列化，根据 `type` 字段分发到具体子类。
  factory RecurrencePattern.fromJson(Map<String, dynamic> json) {
    return switch (json['type'] as String) {
      'every_x_days' => EveryXDaysPattern.fromJson(json),
      'weekly' => WeeklyPattern.fromJson(json),
      'monthly_day' => MonthlyDayPattern.fromJson(json),
      'monthly_week_day' => MonthlyWeekDayPattern.fromJson(json),
      'quarterly_day' => QuarterlyDayPattern.fromJson(json),
      'quarterly_month_day' => QuarterlyMonthDayPattern.fromJson(json),
      'quarterly_month_week_day' => QuarterlyMonthWeekDayPattern.fromJson(json),
      'yearly_day' => YearlyDayPattern.fromJson(json),
      'yearly_month_day' => YearlyMonthDayPattern.fromJson(json),
      'yearly_month_week_day' => YearlyMonthWeekDayPattern.fromJson(json),
      'yearly_quarter_day' => YearlyQuarterDayPattern.fromJson(json),
      'yearly_quarter_month_day' => YearlyQuarterMonthDayPattern.fromJson(json),
      'yearly_quarter_week_day' => YearlyQuarterWeekDayPattern.fromJson(json),
      'yearly_quarter_month_week_day' =>
        YearlyQuarterMonthWeekDayPattern.fromJson(json),
      _ => throw ArgumentError('Unknown recurrence pattern type: ${json['type']}'),
    };
  }
}

// ─── 1. 每A天 → 第B天 ───

/// 每 A 天为周期，周期内第 B 天提醒。
final class EveryXDaysPattern extends RecurrencePattern {
  const EveryXDaysPattern({
    required this.interval,
    required this.days,
  });

  /// A：每 A 天为一个周期（≥1）。
  final int interval;

  /// B：周期内第几天（1 ~ A，可多选）。
  final Set<int> days;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'every_x_days',
        'interval': interval,
        'days': days.toList(),
      };

  factory EveryXDaysPattern.fromJson(Map<String, dynamic> json) =>
      EveryXDaysPattern(
        interval: json['interval'] as int,
        days: (json['days'] as List<dynamic>).cast<int>().toSet(),
      );
}

// ─── 2. 每A周 → 第B天 ───

/// 每 A 周，本周第 B 天提醒。
final class WeeklyPattern extends RecurrencePattern {
  const WeeklyPattern({
    required this.interval,
    required this.weekdays,
  });

  /// A：每 A 周（≥1）。
  final int interval;

  /// B：周几（1=周一 ~ 7=周日，可多选）。
  final Set<int> weekdays;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'weekly',
        'interval': interval,
        'weekdays': weekdays.toList(),
      };

  factory WeeklyPattern.fromJson(Map<String, dynamic> json) => WeeklyPattern(
        interval: json['interval'] as int,
        weekdays: (json['weekdays'] as List<dynamic>).cast<int>().toSet(),
      );
}

// ─── 3. 每A月 → 第B天 ───

/// 每 A 个月，第 B 号提醒。
final class MonthlyDayPattern extends RecurrencePattern {
  const MonthlyDayPattern({
    required this.interval,
    required this.days,
  });

  /// A：每 A 个月（≥1）。
  final int interval;

  /// B：几号（1 ~ 31，可多选）。
  final Set<int> days;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'monthly_day',
        'interval': interval,
        'days': days.toList(),
      };

  factory MonthlyDayPattern.fromJson(Map<String, dynamic> json) =>
      MonthlyDayPattern(
        interval: json['interval'] as int,
        days: (json['days'] as List<dynamic>).cast<int>().toSet(),
      );
}

// ─── 4. 每A月 → 第B周 → 第C天 ───

/// 每 A 个月，第 B 周的第 C 天提醒。
final class MonthlyWeekDayPattern extends RecurrencePattern {
  const MonthlyWeekDayPattern({
    required this.interval,
    required this.items,
  });

  /// A：每 A 个月（≥1）。
  final int interval;

  /// B=week, C=weekday（可多组）。
  final List<WeekDay> items;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'monthly_week_day',
        'interval': interval,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory MonthlyWeekDayPattern.fromJson(Map<String, dynamic> json) =>
      MonthlyWeekDayPattern(
        interval: json['interval'] as int,
        items: (json['items'] as List<dynamic>)
            .map((e) => WeekDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── 5. 每A季度 → 第B天 ───

/// 每 A 个季度，季度内第 B 天提醒。
final class QuarterlyDayPattern extends RecurrencePattern {
  const QuarterlyDayPattern({
    required this.interval,
    required this.days,
  });

  /// A：每 A 个季度（≥1）。
  final int interval;

  /// B：季度内第几天（1 ~ 90+，可多选）。
  final Set<int> days;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'quarterly_day',
        'interval': interval,
        'days': days.toList(),
      };

  factory QuarterlyDayPattern.fromJson(Map<String, dynamic> json) =>
      QuarterlyDayPattern(
        interval: json['interval'] as int,
        days: (json['days'] as List<dynamic>).cast<int>().toSet(),
      );
}

// ─── 6. 每A季度 → 第B月 → 第C天 ───

/// 每 A 个季度，第 B 个月的第 C 天提醒。
final class QuarterlyMonthDayPattern extends RecurrencePattern {
  const QuarterlyMonthDayPattern({
    required this.interval,
    required this.items,
  });

  /// A：每 A 个季度（≥1）。
  final int interval;

  /// B=monthInQuarter, C=day（可多组）。
  final List<MonthInQuarterDay> items;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'quarterly_month_day',
        'interval': interval,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory QuarterlyMonthDayPattern.fromJson(Map<String, dynamic> json) =>
      QuarterlyMonthDayPattern(
        interval: json['interval'] as int,
        items: (json['items'] as List<dynamic>)
            .map((e) => MonthInQuarterDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── 7. 每A季度 → 第B月 → 第C周 → 第D天 ───

/// 每 A 个季度，第 B 个月的第 C 周的第 D 天提醒。
final class QuarterlyMonthWeekDayPattern extends RecurrencePattern {
  const QuarterlyMonthWeekDayPattern({
    required this.interval,
    required this.items,
  });

  /// A：每 A 个季度（≥1）。
  final int interval;

  /// B=monthInQuarter, C=week, D=weekday（可多组）。
  final List<MonthInQuarterWeekDay> items;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'quarterly_month_week_day',
        'interval': interval,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory QuarterlyMonthWeekDayPattern.fromJson(Map<String, dynamic> json) =>
      QuarterlyMonthWeekDayPattern(
        interval: json['interval'] as int,
        items: (json['items'] as List<dynamic>)
            .map((e) =>
                MonthInQuarterWeekDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── 8. 每A年 → 第B天 ───

/// 每 A 年，年内第 B 天提醒。
final class YearlyDayPattern extends RecurrencePattern {
  const YearlyDayPattern({
    required this.interval,
    required this.days,
  });

  /// A：每 A 年（≥1）。
  final int interval;

  /// B：年内第几天（1 ~ 366，可多选）。
  final Set<int> days;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'yearly_day',
        'interval': interval,
        'days': days.toList(),
      };

  factory YearlyDayPattern.fromJson(Map<String, dynamic> json) =>
      YearlyDayPattern(
        interval: json['interval'] as int,
        days: (json['days'] as List<dynamic>).cast<int>().toSet(),
      );
}

// ─── 9. 每A年 → 第B月 → 第C天 ───

/// 每 A 年，第 B 个月的第 C 天提醒。
final class YearlyMonthDayPattern extends RecurrencePattern {
  const YearlyMonthDayPattern({
    required this.interval,
    required this.items,
  });

  /// A：每 A 年（≥1）。
  final int interval;

  /// B=month, C=day（可多组）。
  final List<MonthDay> items;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'yearly_month_day',
        'interval': interval,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory YearlyMonthDayPattern.fromJson(Map<String, dynamic> json) =>
      YearlyMonthDayPattern(
        interval: json['interval'] as int,
        items: (json['items'] as List<dynamic>)
            .map((e) => MonthDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── 10. 每A年 → 第B月 → 第C周 → 第D天 ───

/// 每 A 年，第 B 个月的第 C 周的第 D 天提醒。
final class YearlyMonthWeekDayPattern extends RecurrencePattern {
  const YearlyMonthWeekDayPattern({
    required this.interval,
    required this.items,
  });

  /// A：每 A 年（≥1）。
  final int interval;

  /// B=month, C=week, D=weekday（可多组）。
  final List<MonthWeekDay> items;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'yearly_month_week_day',
        'interval': interval,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory YearlyMonthWeekDayPattern.fromJson(Map<String, dynamic> json) =>
      YearlyMonthWeekDayPattern(
        interval: json['interval'] as int,
        items: (json['items'] as List<dynamic>)
            .map((e) => MonthWeekDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── 11. 每A年 → 第B季度 → 第C天 ───

/// 每 A 年，第 B 个季度的第 C 天提醒。
final class YearlyQuarterDayPattern extends RecurrencePattern {
  const YearlyQuarterDayPattern({
    required this.interval,
    required this.items,
  });

  /// A：每 A 年（≥1）。
  final int interval;

  /// B=quarter, C=day（可多组）。
  final List<QuarterDay> items;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'yearly_quarter_day',
        'interval': interval,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory YearlyQuarterDayPattern.fromJson(Map<String, dynamic> json) =>
      YearlyQuarterDayPattern(
        interval: json['interval'] as int,
        items: (json['items'] as List<dynamic>)
            .map((e) => QuarterDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── 12. 每A年 → 第B季度 → 第C月 → 第D天 ───

/// 每 A 年，第 B 个季度的第 C 个月的第 D 天提醒。
final class YearlyQuarterMonthDayPattern extends RecurrencePattern {
  const YearlyQuarterMonthDayPattern({
    required this.interval,
    required this.items,
  });

  /// A：每 A 年（≥1）。
  final int interval;

  /// B=quarter, C=monthInQuarter, D=day（可多组）。
  final List<YearQuarterMonthDay> items;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'yearly_quarter_month_day',
        'interval': interval,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory YearlyQuarterMonthDayPattern.fromJson(Map<String, dynamic> json) =>
      YearlyQuarterMonthDayPattern(
        interval: json['interval'] as int,
        items: (json['items'] as List<dynamic>)
            .map((e) =>
                YearQuarterMonthDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── 13. 每A年 → 第B季度 → 第C周 → 第D天 ───

/// 每 A 年，第 B 个季度的第 C 周的第 D 天提醒。
final class YearlyQuarterWeekDayPattern extends RecurrencePattern {
  const YearlyQuarterWeekDayPattern({
    required this.interval,
    required this.items,
  });

  /// A：每 A 年（≥1）。
  final int interval;

  /// B=quarter, C=week, D=weekday（可多组）。
  final List<QuarterWeekDay> items;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'yearly_quarter_week_day',
        'interval': interval,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory YearlyQuarterWeekDayPattern.fromJson(Map<String, dynamic> json) =>
      YearlyQuarterWeekDayPattern(
        interval: json['interval'] as int,
        items: (json['items'] as List<dynamic>)
            .map((e) => QuarterWeekDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── 14. 每A年 → 第B季度 → 第C月 → 第D周 → 第E天 ───

/// 每 A 年，第 B 个季度的第 C 个月的第 D 周的第 E 天提醒。
final class YearlyQuarterMonthWeekDayPattern extends RecurrencePattern {
  const YearlyQuarterMonthWeekDayPattern({
    required this.interval,
    required this.items,
  });

  /// A：每 A 年（≥1）。
  final int interval;

  /// B=quarter, C=monthInQuarter, D=week, E=weekday（可多组）。
  final List<YearQuarterMonthWeekDay> items;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'yearly_quarter_month_week_day',
        'interval': interval,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory YearlyQuarterMonthWeekDayPattern.fromJson(
    Map<String, dynamic> json,
  ) =>
      YearlyQuarterMonthWeekDayPattern(
        interval: json['interval'] as int,
        items: (json['items'] as List<dynamic>)
            .map((e) =>
                YearQuarterMonthWeekDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}