import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_pattern.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_rule.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_value_objects.dart';
import 'package:todo_list_module/features/todo_list/services/recurrence_date_calculator.dart';

void main() {
  const calculator = RecurrenceDateCalculator();
  final from = DateTime(2026, 1, 1);
  final to = DateTime(2026, 12, 31);

  List<DateTime> datesOf(RecurrenceRule rule) =>
      calculator.generateDates(rule, from, to);

  String ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  group('RecurrenceDateCalculator', () {
    test('1. 每A天→第B天：每4天第1、4天', () {
      final rule = RecurrenceRule(
        pattern: const EveryXDaysPattern(interval: 4, days: {1, 4}),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      // 周期1: 1/1, 1/4；周期2: 1/5, 1/8；……
      expect(dates, contains(DateTime(2026, 1, 1)));
      expect(dates, contains(DateTime(2026, 1, 4)));
      expect(dates, contains(DateTime(2026, 1, 5)));
      expect(dates, contains(DateTime(2026, 1, 8)));
      expect(dates, isNot(contains(DateTime(2026, 1, 2))));
    });

    test('2. 每A周→第B天：每周周一、周四', () {
      final rule = RecurrenceRule(
        pattern: const WeeklyPattern(interval: 1, weekdays: {1, 4}),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      for (final d in dates) {
        expect(d.weekday == 1 || d.weekday == 4, true,
            reason: '${ymd(d)} 应为周一或周四');
      }
      // 2026-01-01 是周四
      expect(dates, contains(DateTime(2026, 1, 1)));
      expect(dates, contains(DateTime(2026, 1, 5))); // 周一
    });

    test('3. 每A月→第B天：每月1、20号', () {
      final rule = RecurrenceRule(
        pattern: const MonthlyDayPattern(interval: 1, days: {1, 20}),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      expect(dates, contains(DateTime(2026, 1, 1)));
      expect(dates, contains(DateTime(2026, 1, 20)));
      expect(dates, contains(DateTime(2026, 2, 1)));
      expect(dates, contains(DateTime(2026, 12, 20)));
    });

    test('3b. 月日越界：每A月 第31号在2月自动忽略', () {
      final rule = RecurrenceRule(
        pattern: const MonthlyDayPattern(interval: 1, days: {31}),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      expect(dates, contains(DateTime(2026, 1, 31)));
      expect(dates, contains(DateTime(2026, 3, 31)));
      // 2月无31日
      expect(dates, isNot(contains(DateTime(2026, 2, 28))));
      expect(dates, isNot(contains(DateTime(2026, 2, 31)))); // 不应存在
    });

    test('4. 每A月→第B周→第C天：每月第二周周一', () {
      final rule = RecurrenceRule(
        pattern: const MonthlyWeekDayPattern(
          interval: 1,
          items: [WeekDay(week: 2, weekday: 1)],
        ),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      // 2026-01 第二个周一是 1/12
      expect(dates, contains(DateTime(2026, 1, 12)));
      expect(dates, contains(DateTime(2026, 2, 9)));
    });

    test('5. 每A季度→第B天：每季度第15天', () {
      final rule = RecurrenceRule(
        pattern: const QuarterlyDayPattern(interval: 1, days: {15}),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      expect(dates, contains(DateTime(2026, 1, 15)));
      expect(dates, contains(DateTime(2026, 4, 15)));
      expect(dates, contains(DateTime(2026, 7, 15)));
      expect(dates, contains(DateTime(2026, 10, 15)));
    });

    test('5b. 季度天数越界：季度第95天超过则忽略', () {
      final rule = RecurrenceRule(
        pattern: const QuarterlyDayPattern(interval: 1, days: {95}),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      // Q1(1-3月) 91天，95越界；Q2(4-6月) 91天，95越界；全年无命中
      expect(dates, isEmpty);
    });

    test('6. 每A季度→第B月→第C天：每季度第1个月第4天', () {
      final rule = RecurrenceRule(
        pattern: const QuarterlyMonthDayPattern(
          interval: 1,
          items: [MonthInQuarterDay(monthInQuarter: 1, day: 4)],
        ),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      expect(dates, contains(DateTime(2026, 1, 4)));
      expect(dates, contains(DateTime(2026, 4, 4)));
      expect(dates, contains(DateTime(2026, 7, 4)));
    });

    test('7. 每A季度→第B月→第C周→第D天：每季度第2个月第2周周三', () {
      final rule = RecurrenceRule(
        pattern: const QuarterlyMonthWeekDayPattern(
          interval: 1,
          items: [
            MonthInQuarterWeekDay(monthInQuarter: 2, week: 2, weekday: 3),
          ],
        ),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      // 2026-02 第二个周三是 2/11
      expect(dates, contains(DateTime(2026, 2, 11)));
      expect(dates, contains(DateTime(2026, 5, 13)));
    });

    test('8. 每A年→第B天：每年第1天和第100天', () {
      final rule = RecurrenceRule(
        pattern: const YearlyDayPattern(interval: 1, days: {1, 100}),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      expect(dates, contains(DateTime(2026, 1, 1)));
      // 2026-01-01 + 99 天 = 2026-04-10
      expect(dates, contains(DateTime(2026, 4, 10)));
    });

    test('8b. 年天数越界：平年第366天忽略', () {
      final rule = RecurrenceRule(
        pattern: const YearlyDayPattern(interval: 1, days: {366}),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      // 2026 平年 365 天，366 越界
      expect(dates, isEmpty);
    });

    test('9. 每A年→第B月→第C天：每年第2月第20天', () {
      final rule = RecurrenceRule(
        pattern: const YearlyMonthDayPattern(
          interval: 1,
          items: [MonthDay(month: 2, day: 20)],
        ),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      expect(dates, contains(DateTime(2026, 2, 20)));
    });

    test('10. 每A年→第B月→第C周→第D天：每年第3月第2周周二', () {
      final rule = RecurrenceRule(
        pattern: const YearlyMonthWeekDayPattern(
          interval: 1,
          items: [MonthWeekDay(month: 3, week: 2, weekday: 2)],
        ),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      // 2026-03 第二个周二是 3/10
      expect(dates, contains(DateTime(2026, 3, 10)));
    });

    test('11. 每A年→第B季度→第C天：每年第1季度第3天', () {
      final rule = RecurrenceRule(
        pattern: const YearlyQuarterDayPattern(
          interval: 1,
          items: [QuarterDay(quarter: 1, day: 3)],
        ),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      expect(dates, contains(DateTime(2026, 1, 3)));
    });

    test('11b. 每A年→第B季度→第C天：第4季度第90天', () {
      final rule = RecurrenceRule(
        pattern: const YearlyQuarterDayPattern(
          interval: 1,
          items: [QuarterDay(quarter: 4, day: 90)],
        ),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      // Q4 = 10-12月，10/1 + 89 天 = 12/29
      expect(dates, contains(DateTime(2026, 12, 29)));
    });

    test('12. 每A年→第B季度→第C月→第D天', () {
      final rule = RecurrenceRule(
        pattern: const YearlyQuarterMonthDayPattern(
          interval: 1,
          items: [YearQuarterMonthDay(quarter: 1, monthInQuarter: 2, day: 4)],
        ),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      // Q1 第2个月 = 2月，第4天
      expect(dates, contains(DateTime(2026, 2, 4)));
    });

    test('13. 每A年→第B季度→第C周→第D天：第1季度第2周周一', () {
      final rule = RecurrenceRule(
        pattern: const YearlyQuarterWeekDayPattern(
          interval: 1,
          items: [QuarterWeekDay(quarter: 1, week: 2, weekday: 1)],
        ),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      // Q1 从 1/1 起，第二个周一 = 1/12
      expect(dates, contains(DateTime(2026, 1, 12)));
    });

    test('14. 每A年→第B季度→第C月→第D周→第E天', () {
      final rule = RecurrenceRule(
        pattern: const YearlyQuarterMonthWeekDayPattern(
          interval: 1,
          items: [
            YearQuarterMonthWeekDay(
              quarter: 2,
              monthInQuarter: 3,
              week: 1,
              weekday: 1,
            ),
          ],
        ),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      // Q2 第3个月 = 6月，第一个周一 = 6/1
      expect(dates, contains(DateTime(2026, 6, 1)));
    });

    test('区间外不返回；尊重 startDate/endDate', () {
      final rule = RecurrenceRule(
        pattern: const MonthlyDayPattern(interval: 1, days: {5}),
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 10),
      );
      final dates = calculator.generateDates(rule, from, to);
      expect(dates, [DateTime(2026, 3, 5)]); // 只有 3/5 在 [3/1, 3/10] 内
    });

    test('结果升序去重', () {
      final rule = RecurrenceRule(
        pattern: const WeeklyPattern(interval: 1, weekdays: {1}),
        startDate: DateTime(2026, 1, 1),
      );
      final dates = datesOf(rule);
      for (var i = 1; i < dates.length; i++) {
        expect(dates[i].isAfter(dates[i - 1]), true);
      }
      expect(dates.toSet().length, dates.length);
    });
  });
}