import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_pattern.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_rule.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_value_objects.dart';
import 'package:todo_list_module/features/todo_list/widgets/recurrence_rule_editor.dart';

void main() {
  final start = DateTime(2026, 8, 1);

  RecurrenceRule rule(RecurrencePattern p) =>
      RecurrenceRule(pattern: p, startDate: start);

  group('describeRule 描述 14 种循环方式', () {
    test('每A天', () {
      expect(
        describeRule(rule(EveryXDaysPattern(interval: 4, days: {1, 4}))),
        '每4天，第1、4天',
      );
    });

    test('每A周', () {
      expect(
        describeRule(rule(WeeklyPattern(interval: 1, weekdays: {1, 4}))),
        '每1周，周一、周四',
      );
    });

    test('每A月 - 第B天', () {
      expect(
        describeRule(rule(MonthlyDayPattern(interval: 1, days: {1, 15}))),
        '每1月，1、15号',
      );
    });

    test('每A月 - 第B周第C天', () {
      expect(
        describeRule(rule(MonthlyWeekDayPattern(
          interval: 1,
          items: const [WeekDay(week: 2, weekday: 1)],
        ))),
        '每1月，第2周周一',
      );
    });

    test('每A季度 - 第B天', () {
      expect(
        describeRule(rule(QuarterlyDayPattern(interval: 1, days: {15, 90}))),
        '每1季度，第15、90天',
      );
    });

    test('每A季度 - 第B月第C天', () {
      expect(
        describeRule(rule(QuarterlyMonthDayPattern(
          interval: 1,
          items: const [MonthInQuarterDay(monthInQuarter: 1, day: 4)],
        ))),
        '每1季度，第1月4号',
      );
    });

    test('每A季度 - 第B月第C周第D天', () {
      expect(
        describeRule(rule(QuarterlyMonthWeekDayPattern(
          interval: 1,
          items: const [MonthInQuarterWeekDay(monthInQuarter: 1, week: 2, weekday: 1)],
        ))),
        '每1季度，第1月第2周周一',
      );
    });

    test('每A年 - 第B天', () {
      expect(
        describeRule(rule(YearlyDayPattern(interval: 1, days: {1, 100}))),
        '每1年，第1、100天',
      );
    });

    test('每A年 - 第B月第C天', () {
      expect(
        describeRule(rule(YearlyMonthDayPattern(
          interval: 1,
          items: const [MonthDay(month: 2, day: 20)],
        ))),
        '每1年，2月20号',
      );
    });

    test('每A年 - 第B季第C季第D周第E天 描述不含空档', () {
      expect(
        describeRule(rule(YearlyQuarterMonthWeekDayPattern(
          interval: 2,
          items: const [
            YearQuarterMonthWeekDay(quarter: 2, monthInQuarter: 3, week: 1, weekday: 1),
          ],
        ))),
        '每2年，第2季度第3月第1周周一',
      );
    });
  });
}