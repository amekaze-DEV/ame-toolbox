import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_pattern.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_value_objects.dart';

void main() {
  group('RecurrencePattern', () {
    test('EveryXDaysPattern round-trip', () {
      const pattern = EveryXDaysPattern(interval: 4, days: {1, 4});
      final restored = RecurrencePattern.fromJson(pattern.toJson());
      expect(restored, isA<EveryXDaysPattern>());
      expect((restored as EveryXDaysPattern).interval, 4);
      expect(restored.days, {1, 4});
    });

    test('WeeklyPattern round-trip', () {
      const pattern = WeeklyPattern(interval: 1, weekdays: {1, 4});
      final restored = RecurrencePattern.fromJson(pattern.toJson());
      expect(restored, isA<WeeklyPattern>());
      expect((restored as WeeklyPattern).interval, 1);
      expect(restored.weekdays, {1, 4});
    });

    test('MonthlyDayPattern round-trip', () {
      const pattern = MonthlyDayPattern(interval: 1, days: {1, 4, 20});
      final restored = RecurrencePattern.fromJson(pattern.toJson());
      expect(restored, isA<MonthlyDayPattern>());
      expect((restored as MonthlyDayPattern).days, {1, 4, 20});
    });

    test('MonthlyWeekDayPattern round-trip', () {
      const pattern = MonthlyWeekDayPattern(
        interval: 1,
        items: [WeekDay(week: 1, weekday: 1), WeekDay(week: 2, weekday: 3)],
      );
      final restored = RecurrencePattern.fromJson(pattern.toJson());
      expect(restored, isA<MonthlyWeekDayPattern>());
      expect((restored as MonthlyWeekDayPattern).items.length, 2);
    });

    test('QuarterlyDayPattern round-trip', () {
      const pattern = QuarterlyDayPattern(interval: 1, days: {15, 90});
      final restored = RecurrencePattern.fromJson(pattern.toJson());
      expect(restored, isA<QuarterlyDayPattern>());
      expect((restored as QuarterlyDayPattern).days, {15, 90});
    });

    test('QuarterlyMonthDayPattern round-trip', () {
      const pattern = QuarterlyMonthDayPattern(
        interval: 1,
        items: [
          MonthInQuarterDay(monthInQuarter: 1, day: 4),
          MonthInQuarterDay(monthInQuarter: 3, day: 10),
        ],
      );
      final restored = RecurrencePattern.fromJson(pattern.toJson());
      expect(restored, isA<QuarterlyMonthDayPattern>());
    });

    test('QuarterlyMonthWeekDayPattern round-trip', () {
      const pattern = QuarterlyMonthWeekDayPattern(
        interval: 1,
        items: [
          MonthInQuarterWeekDay(
            monthInQuarter: 1,
            week: 1,
            weekday: 3,
          ),
        ],
      );
      final restored = RecurrencePattern.fromJson(pattern.toJson());
      expect(restored, isA<QuarterlyMonthWeekDayPattern>());
    });

    test('YearlyDayPattern round-trip', () {
      const pattern = YearlyDayPattern(interval: 1, days: {1, 100, 366});
      final restored = RecurrencePattern.fromJson(pattern.toJson());
      expect(restored, isA<YearlyDayPattern>());
      expect((restored as YearlyDayPattern).days, {1, 100, 366});
    });

    test('YearlyMonthDayPattern round-trip', () {
      const pattern = YearlyMonthDayPattern(
        interval: 1,
        items: [
          MonthDay(month: 2, day: 20),
          MonthDay(month: 6, day: 15),
        ],
      );
      final restored = RecurrencePattern.fromJson(pattern.toJson());
      expect(restored, isA<YearlyMonthDayPattern>());
    });

    test('YearlyMonthWeekDayPattern round-trip', () {
      const pattern = YearlyMonthWeekDayPattern(
        interval: 1,
        items: [
          MonthWeekDay(month: 3, week: 2, weekday: 2),
        ],
      );
      final restored = RecurrencePattern.fromJson(pattern.toJson());
      expect(restored, isA<YearlyMonthWeekDayPattern>());
    });

    test('YearlyQuarterDayPattern round-trip', () {
      const pattern = YearlyQuarterDayPattern(
        interval: 1,
        items: [
          QuarterDay(quarter: 1, day: 3),
          QuarterDay(quarter: 4, day: 50),
        ],
      );
      final restored = RecurrencePattern.fromJson(pattern.toJson());
      expect(restored, isA<YearlyQuarterDayPattern>());
    });

    test('YearlyQuarterMonthDayPattern round-trip', () {
      const pattern = YearlyQuarterMonthDayPattern(
        interval: 1,
        items: [
          YearQuarterMonthDay(quarter: 1, monthInQuarter: 2, day: 4),
          YearQuarterMonthDay(quarter: 3, monthInQuarter: 1, day: 20),
        ],
      );
      final restored = RecurrencePattern.fromJson(pattern.toJson());
      expect(restored, isA<YearlyQuarterMonthDayPattern>());
    });

    test('YearlyQuarterWeekDayPattern round-trip', () {
      const pattern = YearlyQuarterWeekDayPattern(
        interval: 1,
        items: [
          QuarterWeekDay(quarter: 1, week: 2, weekday: 1),
        ],
      );
      final restored = RecurrencePattern.fromJson(pattern.toJson());
      expect(restored, isA<YearlyQuarterWeekDayPattern>());
    });

    test('YearlyQuarterMonthWeekDayPattern round-trip', () {
      const pattern = YearlyQuarterMonthWeekDayPattern(
        interval: 1,
        items: [
          YearQuarterMonthWeekDay(
            quarter: 2,
            monthInQuarter: 3,
            week: 1,
            weekday: 1,
          ),
        ],
      );
      final restored = RecurrencePattern.fromJson(pattern.toJson());
      expect(restored, isA<YearlyQuarterMonthWeekDayPattern>());
    });

    test('未知 type 抛出 ArgumentError', () {
      expect(
        () => RecurrencePattern.fromJson(const {'type': 'unknown'}),
        throwsArgumentError,
      );
    });
  });
}