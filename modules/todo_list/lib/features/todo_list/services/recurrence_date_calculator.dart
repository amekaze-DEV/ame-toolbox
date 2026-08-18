import '../models/recurrence_pattern.dart';
import '../models/recurrence_rule.dart';

/// 循环日期计算引擎。
///
/// 根据单一 [RecurrenceRule] 在指定闭区间 `[from, to]` 内计算所有命中日期。
/// 14 种周期方式通过 `switch` 分发到各自生成器；所有日期判定为纯函数，
/// 便于单元测试。命中日期满足：
/// - 不早于规则起始 [RecurrenceRule.startDate]；
/// - 不晚于规则终止 [RecurrenceRule.endDate]（若存在）；
/// - 位于区间 `[from, to]` 内；
/// - 越界规则（月日越界 / 季度天数 / 年天数 / 周-周几）自动忽略。
class RecurrenceDateCalculator {
  const RecurrenceDateCalculator();

  /// 计算 [rule] 在 `[from, to]` 闭区间内的全部命中日期，升序去重返回。
  List<DateTime> generateDates(
    RecurrenceRule rule,
    DateTime from,
    DateTime to,
  ) {
    final pattern = rule.pattern;
    return switch (pattern) {
      EveryXDaysPattern p => _generateEveryXDays(rule, p, from, to),
      WeeklyPattern p => _generateWeekly(rule, p, from, to),
      MonthlyDayPattern p => _generateMonthlyDay(rule, p, from, to),
      MonthlyWeekDayPattern p => _generateMonthlyWeekDay(rule, p, from, to),
      QuarterlyDayPattern p => _generateQuarterlyDay(rule, p, from, to),
      QuarterlyMonthDayPattern p => _generateQuarterlyMonthDay(rule, p, from, to),
      QuarterlyMonthWeekDayPattern p =>
        _generateQuarterlyMonthWeekDay(rule, p, from, to),
      YearlyDayPattern p => _generateYearlyDay(rule, p, from, to),
      YearlyMonthDayPattern p => _generateYearlyMonthDay(rule, p, from, to),
      YearlyMonthWeekDayPattern p => _generateYearlyMonthWeekDay(rule, p, from, to),
      YearlyQuarterDayPattern p => _generateYearlyQuarterDay(rule, p, from, to),
      YearlyQuarterMonthDayPattern p =>
        _generateYearlyQuarterMonthDay(rule, p, from, to),
      YearlyQuarterWeekDayPattern p =>
        _generateYearlyQuarterWeekDay(rule, p, from, to),
      YearlyQuarterMonthWeekDayPattern p =>
        _generateYearlyQuarterMonthWeekDay(rule, p, from, to),
    };
  }

  // ── 周期与日期工具 ──

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 日历安全的日期偏移（自动处理跨月/跨年及月末归一化）。
  static DateTime _addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  /// 日历安全的月份偏移，返回目标月 1 日。
  static DateTime _addMonthsStart(DateTime d, int months) =>
      DateTime(d.year, d.month + months, 1);

  /// 自基准日 [epoch] 起的绝对天数序号（用 UTC 避免 DST 干扰）。
  static int _dayIndex(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

  /// `[effectiveFrom, effectiveTo]` 为叠加规则起止与查询区间后的有效命中范围。
  static (DateTime, DateTime) _effectiveRange(
    RecurrenceRule rule,
    DateTime from,
    DateTime to,
  ) {
    final start = _dateOnly(rule.startDate);
    final effectiveFrom =
        from.isAfter(start) ? _dateOnly(from) : start;
    var effectiveTo = _dateOnly(to);
    if (rule.endDate != null) {
      final end = _dateOnly(rule.endDate!);
      if (end.isBefore(effectiveTo)) effectiveTo = end;
    }
    return (effectiveFrom, effectiveTo);
  }

  static bool _inRange(DateTime date, DateTime from, DateTime to) =>
      !date.isBefore(from) && !date.isAfter(to);

  // ── 1. 每A天 → 第B天 ──

  List<DateTime> _generateEveryXDays(
    RecurrenceRule rule,
    EveryXDaysPattern p,
    DateTime from,
    DateTime to,
  ) {
    final (f, t) = _effectiveRange(rule, from, to);
    if (f.isAfter(t)) return const [];
    final interval = p.interval < 1 ? 1 : p.interval;
    final baseIdx = _dayIndex(rule.startDate);
    final firstK = ((_dayIndex(f) - baseIdx) ~/ interval) - 1;
    final lastK = ((_dayIndex(t) - baseIdx) ~/ interval) + 1;
    final result = <DateTime>{};
    for (var k = firstK < 0 ? 0 : firstK; k <= lastK; k++) {
      final cycleStart = _addDays(_dateOnly(rule.startDate), k * interval);
      for (final day in p.days) {
        if (day < 1 || day > interval) continue;
        final date = _addDays(cycleStart, day - 1);
        if (_inRange(date, f, t)) result.add(date);
      }
    }
    return result.toList()..sort();
  }

  // ── 2. 每A周 → 第B天 ──

  List<DateTime> _generateWeekly(
    RecurrenceRule rule,
    WeeklyPattern p,
    DateTime from,
    DateTime to,
  ) {
    final (f, t) = _effectiveRange(rule, from, to);
    if (f.isAfter(t)) return const [];
    final interval = p.interval < 1 ? 1 : p.interval;
    // 以 startDate 所在周的周一为周期基准。
    final rawBase = _dateOnly(rule.startDate);
    final base = _addDays(
      rawBase,
      1 - rawBase.weekday, // DateTime.weekday: 1=周一 ~ 7=周日
    );
    final baseIdx = _dayIndex(base);
    final weekLen = interval * 7;
    final firstK = ((_dayIndex(f) - baseIdx) ~/ weekLen) - 1;
    final lastK = ((_dayIndex(t) - baseIdx) ~/ weekLen) + 1;
    final result = <DateTime>{};
    for (var k = firstK < 0 ? 0 : firstK; k <= lastK; k++) {
      final weekStart = _addDays(base, k * weekLen);
      for (final wd in p.weekdays) {
        if (wd < 1 || wd > 7) continue;
        final date = _addDays(weekStart, wd - 1); // wd 为绝对周几，周一=1
        if (_inRange(date, f, t)) result.add(date);
      }
    }
    return result.toList()..sort();
  }

  // ── 3. 每A月 → 第B天 ──

  List<DateTime> _generateMonthlyDay(
    RecurrenceRule rule,
    MonthlyDayPattern p,
    DateTime from,
    DateTime to,
  ) {
    final (f, t) = _effectiveRange(rule, from, to);
    if (f.isAfter(t)) return const [];
    final interval = p.interval < 1 ? 1 : p.interval;
    final base = _dateOnly(rule.startDate);
    final baseMonth = base.year * 12 + base.month;
    final fromMonth = f.year * 12 + f.month;
    final toMonth = t.year * 12 + t.month;
    final firstK = ((fromMonth - baseMonth) ~/ interval) - 1;
    final lastK = ((toMonth - baseMonth) ~/ interval) + 1;
    final result = <DateTime>{};
    for (var k = firstK < 0 ? 0 : firstK; k <= lastK; k++) {
      final ym = _addMonthsStart(base, k * interval);
      for (final day in p.days) {
        if (day < 1 || day > 31) continue;
        final date = DateTime(ym.year, ym.month, day);
        if (date.month != ym.month) continue; // 月日越界，忽略
        if (_inRange(date, f, t)) result.add(date);
      }
    }
    return result.toList()..sort();
  }

  // ── 4. 每A月 → 第B周 → 第C天 ──

  List<DateTime> _generateMonthlyWeekDay(
    RecurrenceRule rule,
    MonthlyWeekDayPattern p,
    DateTime from,
    DateTime to,
  ) {
    final (f, t) = _effectiveRange(rule, from, to);
    if (f.isAfter(t)) return const [];
    final interval = p.interval < 1 ? 1 : p.interval;
    final base = _dateOnly(rule.startDate);
    final baseMonth = base.year * 12 + base.month;
    final fromMonth = f.year * 12 + f.month;
    final toMonth = t.year * 12 + t.month;
    final firstK = ((fromMonth - baseMonth) ~/ interval) - 1;
    final lastK = ((toMonth - baseMonth) ~/ interval) + 1;
    final result = <DateTime>{};
    for (var k = firstK < 0 ? 0 : firstK; k <= lastK; k++) {
      final ym = _addMonthsStart(base, k * interval);
      for (final item in p.items) {
        final date = _nthWeekdayOfMonth(ym.year, ym.month, item.week, item.weekday);
        if (date == null) continue;
        if (_inRange(date, f, t)) result.add(date);
      }
    }
    return result.toList()..sort();
  }

  // ── 5. 每A季度 → 第B天 ──

  List<DateTime> _generateQuarterlyDay(
    RecurrenceRule rule,
    QuarterlyDayPattern p,
    DateTime from,
    DateTime to,
  ) {
    final (f, t) = _effectiveRange(rule, from, to);
    if (f.isAfter(t)) return const [];
    final interval = p.interval < 1 ? 1 : p.interval;
    final baseQuarter = _quarterIndex(rule.startDate);
    final firstK = ((_quarterIndex(f) - baseQuarter) ~/ interval) - 1;
    final lastK = ((_quarterIndex(t) - baseQuarter) ~/ interval) + 1;
    final result = <DateTime>{};
    for (var k = firstK < 0 ? 0 : firstK; k <= lastK; k++) {
      final qStart = _quarterStart(rule.startDate, k * interval);
      final qEnd = _addMonthsStart(qStart, 3);
      for (final day in p.days) {
        if (day < 1) continue;
        final date = _addDays(qStart, day - 1);
        if (date.isAfter(qEnd)) continue; // 超过本季度天数，忽略
        if (_inRange(date, f, t)) result.add(date);
      }
    }
    return result.toList()..sort();
  }

  // ── 6. 每A季度 → 第B月 → 第C天 ──

  List<DateTime> _generateQuarterlyMonthDay(
    RecurrenceRule rule,
    QuarterlyMonthDayPattern p,
    DateTime from,
    DateTime to,
  ) {
    final (f, t) = _effectiveRange(rule, from, to);
    if (f.isAfter(t)) return const [];
    final interval = p.interval < 1 ? 1 : p.interval;
    final baseQuarter = _quarterIndex(rule.startDate);
    final firstK = ((_quarterIndex(f) - baseQuarter) ~/ interval) - 1;
    final lastK = ((_quarterIndex(t) - baseQuarter) ~/ interval) + 1;
    final result = <DateTime>{};
    for (var k = firstK < 0 ? 0 : firstK; k <= lastK; k++) {
      final qStart = _quarterStart(rule.startDate, k * interval);
      for (final item in p.items) {
        final absMonth = _addMonthsStart(qStart, item.monthInQuarter - 1);
        final date = DateTime(absMonth.year, absMonth.month, item.day);
        if (date.month != absMonth.month) continue;
        if (_inRange(date, f, t)) result.add(date);
      }
    }
    return result.toList()..sort();
  }

  // ── 7. 每A季度 → 第B月 → 第C周 → 第D天 ──

  List<DateTime> _generateQuarterlyMonthWeekDay(
    RecurrenceRule rule,
    QuarterlyMonthWeekDayPattern p,
    DateTime from,
    DateTime to,
  ) {
    final (f, t) = _effectiveRange(rule, from, to);
    if (f.isAfter(t)) return const [];
    final interval = p.interval < 1 ? 1 : p.interval;
    final baseQuarter = _quarterIndex(rule.startDate);
    final firstK = ((_quarterIndex(f) - baseQuarter) ~/ interval) - 1;
    final lastK = ((_quarterIndex(t) - baseQuarter) ~/ interval) + 1;
    final result = <DateTime>{};
    for (var k = firstK < 0 ? 0 : firstK; k <= lastK; k++) {
      final qStart = _quarterStart(rule.startDate, k * interval);
      for (final item in p.items) {
        final absMonth = _addMonthsStart(qStart, item.monthInQuarter - 1);
        final date = _nthWeekdayOfMonth(
          absMonth.year,
          absMonth.month,
          item.week,
          item.weekday,
        );
        if (date == null) continue;
        if (_inRange(date, f, t)) result.add(date);
      }
    }
    return result.toList()..sort();
  }

  // ── 8. 每A年 → 第B天 ──

  List<DateTime> _generateYearlyDay(
    RecurrenceRule rule,
    YearlyDayPattern p,
    DateTime from,
    DateTime to,
  ) {
    final (f, t) = _effectiveRange(rule, from, to);
    if (f.isAfter(t)) return const [];
    final interval = p.interval < 1 ? 1 : p.interval;
    final baseYear = rule.startDate.year;
    final firstK = ((f.year - baseYear) ~/ interval) - 1;
    final lastK = ((t.year - baseYear) ~/ interval) + 1;
    final result = <DateTime>{};
    for (var k = firstK < 0 ? 0 : firstK; k <= lastK; k++) {
      final year = baseYear + k * interval;
      final yearStart = DateTime(year, 1, 1);
      for (final day in p.days) {
        if (day < 1) continue;
        final date = _addDays(yearStart, day - 1);
        if (date.year != year) continue; // 超过当年天数，忽略
        if (_inRange(date, f, t)) result.add(date);
      }
    }
    return result.toList()..sort();
  }

  // ── 9. 每A年 → 第B月 → 第C天 ──

  List<DateTime> _generateYearlyMonthDay(
    RecurrenceRule rule,
    YearlyMonthDayPattern p,
    DateTime from,
    DateTime to,
  ) {
    final (f, t) = _effectiveRange(rule, from, to);
    if (f.isAfter(t)) return const [];
    final interval = p.interval < 1 ? 1 : p.interval;
    final baseYear = rule.startDate.year;
    final firstK = ((f.year - baseYear) ~/ interval) - 1;
    final lastK = ((t.year - baseYear) ~/ interval) + 1;
    final result = <DateTime>{};
    for (var k = firstK < 0 ? 0 : firstK; k <= lastK; k++) {
      final year = baseYear + k * interval;
      for (final item in p.items) {
        final date = DateTime(year, item.month, item.day);
        if (date.month != item.month) continue;
        if (_inRange(date, f, t)) result.add(date);
      }
    }
    return result.toList()..sort();
  }

  // ── 10. 每A年 → 第B月 → 第C周 → 第D天 ──

  List<DateTime> _generateYearlyMonthWeekDay(
    RecurrenceRule rule,
    YearlyMonthWeekDayPattern p,
    DateTime from,
    DateTime to,
  ) {
    final (f, t) = _effectiveRange(rule, from, to);
    if (f.isAfter(t)) return const [];
    final interval = p.interval < 1 ? 1 : p.interval;
    final baseYear = rule.startDate.year;
    final firstK = ((f.year - baseYear) ~/ interval) - 1;
    final lastK = ((t.year - baseYear) ~/ interval) + 1;
    final result = <DateTime>{};
    for (var k = firstK < 0 ? 0 : firstK; k <= lastK; k++) {
      final year = baseYear + k * interval;
      for (final item in p.items) {
        final date = _nthWeekdayOfMonth(year, item.month, item.week, item.weekday);
        if (date == null) continue;
        if (_inRange(date, f, t)) result.add(date);
      }
    }
    return result.toList()..sort();
  }

  // ── 11. 每A年 → 第B季度 → 第C天 ──

  List<DateTime> _generateYearlyQuarterDay(
    RecurrenceRule rule,
    YearlyQuarterDayPattern p,
    DateTime from,
    DateTime to,
  ) {
    final (f, t) = _effectiveRange(rule, from, to);
    if (f.isAfter(t)) return const [];
    final interval = p.interval < 1 ? 1 : p.interval;
    final baseYear = rule.startDate.year;
    final firstK = ((f.year - baseYear) ~/ interval) - 1;
    final lastK = ((t.year - baseYear) ~/ interval) + 1;
    final result = <DateTime>{};
    for (var k = firstK < 0 ? 0 : firstK; k <= lastK; k++) {
      final year = baseYear + k * interval;
      for (final item in p.items) {
        final qStart = DateTime(year, (item.quarter - 1) * 3 + 1, 1);
        final qEnd = _addMonthsStart(qStart, 3);
        final date = _addDays(qStart, item.day - 1);
        if (date.isAfter(qEnd)) continue;
        if (_inRange(date, f, t)) result.add(date);
      }
    }
    return result.toList()..sort();
  }

  // ── 12. 每A年 → 第B季度 → 第C月 → 第D天 ──

  List<DateTime> _generateYearlyQuarterMonthDay(
    RecurrenceRule rule,
    YearlyQuarterMonthDayPattern p,
    DateTime from,
    DateTime to,
  ) {
    final (f, t) = _effectiveRange(rule, from, to);
    if (f.isAfter(t)) return const [];
    final interval = p.interval < 1 ? 1 : p.interval;
    final baseYear = rule.startDate.year;
    final firstK = ((f.year - baseYear) ~/ interval) - 1;
    final lastK = ((t.year - baseYear) ~/ interval) + 1;
    final result = <DateTime>{};
    for (var k = firstK < 0 ? 0 : firstK; k <= lastK; k++) {
      final year = baseYear + k * interval;
      for (final item in p.items) {
        final qStart = DateTime(year, (item.quarter - 1) * 3 + 1, 1);
        final absMonth = _addMonthsStart(qStart, item.monthInQuarter - 1);
        final date = DateTime(absMonth.year, absMonth.month, item.day);
        if (date.month != absMonth.month) continue;
        if (_inRange(date, f, t)) result.add(date);
      }
    }
    return result.toList()..sort();
  }

  // ── 13. 每A年 → 第B季度 → 第C周 → 第D天 ──

  List<DateTime> _generateYearlyQuarterWeekDay(
    RecurrenceRule rule,
    YearlyQuarterWeekDayPattern p,
    DateTime from,
    DateTime to,
  ) {
    final (f, t) = _effectiveRange(rule, from, to);
    if (f.isAfter(t)) return const [];
    final interval = p.interval < 1 ? 1 : p.interval;
    final baseYear = rule.startDate.year;
    final firstK = ((f.year - baseYear) ~/ interval) - 1;
    final lastK = ((t.year - baseYear) ~/ interval) + 1;
    final result = <DateTime>{};
    for (var k = firstK < 0 ? 0 : firstK; k <= lastK; k++) {
      final year = baseYear + k * interval;
      for (final item in p.items) {
        final qStart = DateTime(year, (item.quarter - 1) * 3 + 1, 1);
        final qEnd = _addMonthsStart(qStart, 3);
        final firstWeekday = _addDays(
          qStart,
          (item.weekday - qStart.weekday + 7) % 7,
        );
        final date = _addDays(firstWeekday, (item.week - 1) * 7);
        if (date.isAfter(qEnd)) continue;
        if (_inRange(date, f, t)) result.add(date);
      }
    }
    return result.toList()..sort();
  }

  // ── 14. 每A年 → 第B季度 → 第C月 → 第D周 → 第E天 ──

  List<DateTime> _generateYearlyQuarterMonthWeekDay(
    RecurrenceRule rule,
    YearlyQuarterMonthWeekDayPattern p,
    DateTime from,
    DateTime to,
  ) {
    final (f, t) = _effectiveRange(rule, from, to);
    if (f.isAfter(t)) return const [];
    final interval = p.interval < 1 ? 1 : p.interval;
    final baseYear = rule.startDate.year;
    final firstK = ((f.year - baseYear) ~/ interval) - 1;
    final lastK = ((t.year - baseYear) ~/ interval) + 1;
    final result = <DateTime>{};
    for (var k = firstK < 0 ? 0 : firstK; k <= lastK; k++) {
      final year = baseYear + k * interval;
      for (final item in p.items) {
        final qStart = DateTime(year, (item.quarter - 1) * 3 + 1, 1);
        final absMonth = _addMonthsStart(qStart, item.monthInQuarter - 1);
        final date = _nthWeekdayOfMonth(
          absMonth.year,
          absMonth.month,
          item.week,
          item.weekday,
        );
        if (date == null) continue;
        if (_inRange(date, f, t)) result.add(date);
      }
    }
    return result.toList()..sort();
  }

  // ── 私有工具 ──

  /// 返回某年某月第 [week] 周（第几个）星期 [weekday] 的日期；
  /// 若该月不存在该周/周几则返回 null。
  static DateTime? _nthWeekdayOfMonth(
    int year,
    int month,
    int week,
    int weekday,
  ) {
    if (week < 1 || weekday < 1 || weekday > 7) return null;
    final firstOfMonth = DateTime(year, month, 1);
    final firstWeekday = _addDays(
      firstOfMonth,
      (weekday - firstOfMonth.weekday + 7) % 7,
    );
    final date = _addDays(firstWeekday, (week - 1) * 7);
    return date.month == month ? date : null;
  }

  /// 季度序号：`(year*4 + 本季度0基索引)`。
  static int _quarterIndex(DateTime d) =>
      d.year * 4 + ((d.month - 1) ~/ 3);

  /// 返回距 [rule.startDate] `kQuarter` 个季度后的季度首日。
  static DateTime _quarterStart(DateTime start, int kQuarter) {
    final baseQuarter0 = (start.month - 1) ~/ 3;
    final totalOffset = baseQuarter0 + kQuarter;
    final year = start.year + totalOffset ~/ 4;
    final month0 = totalOffset % 4;
    return DateTime(year, month0 * 3 + 1, 1);
  }
}