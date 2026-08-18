/// 倒班助手模块日期工具函数。
library;

/// 周起始日：周一。
const int _weekStartDay = DateTime.monday;

/// 将 [date] 规范为仅含日期部分（00:00:00）。
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// 获取 [date] 所在周的起始日（周一）。
///
/// [date] 会被规范为日期部分后计算。
DateTime weekStart(DateTime date) {
  final normalized = dateOnly(date);
  // weekday: Monday=1, Sunday=7
  final daysSinceMonday = normalized.weekday - _weekStartDay;
  return normalized.subtract(Duration(days: daysSinceMonday));
}

/// 获取 [date] 所在周的结束日（周日）。
///
/// [date] 会被规范为日期部分后计算。
DateTime weekEnd(DateTime date) => weekStart(date).add(const Duration(days: 6));

/// 生成 [date] 所在周的 7 天日期列表（周一至周日）。
List<DateTime> daysOfWeek(DateTime date) {
  final start = weekStart(date);
  return List.generate(7, (i) => start.add(Duration(days: i)));
}

/// 判断 [a] 与 [b] 是否为同一天（忽略时间）。
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 将 [date] 格式化为周范围展示字符串，如“8月1日 - 8月7日”。
String formatWeekRange(DateTime date) {
  final start = weekStart(date);
  final end = weekEnd(date);
  return '${start.month}月${start.day}日 - ${end.month}月${end.day}日';
}

/// 获取 [date] 所在月的起始日（1号）。
DateTime monthStart(DateTime date) => DateTime(date.year, date.month, 1);

/// 获取 [date] 所在月的总天数。
int daysInMonth(DateTime date) {
  final nextMonth = DateTime(date.year, date.month + 1, 1);
  return nextMonth.subtract(const Duration(days: 1)).day;
}

/// 生成 [date] 所在月的完整周列表。
///
/// 每周包含 7 天（周一至周日），首周/末周不足部分用上个月/下个月日期补齐，
/// 保证日历网格为完整的 6 行（或必要时更少）。
List<List<DateTime>> monthWeeks(DateTime date) {
  final firstDay = monthStart(date);
  final start = weekStart(firstDay);
  final daysInCurrentMonth = daysInMonth(date);
  final lastDay = DateTime(date.year, date.month, daysInCurrentMonth);
  final totalDays = lastDay.difference(start).inDays + 1;
  final totalWeeks = (totalDays / 7).ceil();

  return List.generate(
    totalWeeks,
    (weekIndex) => List.generate(
      7,
      (dayIndex) => start.add(Duration(days: weekIndex * 7 + dayIndex)),
    ),
  );
}

/// 将 [date] 格式化为年月展示字符串，如"2027年8月"。
String formatMonthYear(DateTime date) => '${date.year}年${date.month}月';

/// 将年份格式化为展示字符串，如"2026年"。
String formatYear(int year) => '$year年';

/// 将年份范围格式化为展示字符串，如"2020-2031年"。
String formatYearRange(int startYear, int endYear) => '$startYear-$endYear年';
