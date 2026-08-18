import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_value_objects.dart';

void main() {
  group('Recurrence value objects', () {
    test('WeekDay toJson / fromJson 往返正确', () {
      const value = WeekDay(week: 2, weekday: 1);
      final restored = WeekDay.fromJson(value.toJson());
      expect(restored.week, 2);
      expect(restored.weekday, 1);
    });

    test('MonthInQuarterDay toJson / fromJson 往返正确', () {
      const value = MonthInQuarterDay(monthInQuarter: 3, day: 15);
      final restored = MonthInQuarterDay.fromJson(value.toJson());
      expect(restored.monthInQuarter, 3);
      expect(restored.day, 15);
    });

    test('MonthInQuarterWeekDay toJson / fromJson 往返正确', () {
      const value = MonthInQuarterWeekDay(monthInQuarter: 1, week: 2, weekday: 5);
      final restored = MonthInQuarterWeekDay.fromJson(value.toJson());
      expect(restored.monthInQuarter, 1);
      expect(restored.week, 2);
      expect(restored.weekday, 5);
    });

    test('MonthDay toJson / fromJson 往返正确', () {
      const value = MonthDay(month: 12, day: 31);
      final restored = MonthDay.fromJson(value.toJson());
      expect(restored.month, 12);
      expect(restored.day, 31);
    });

    test('MonthWeekDay toJson / fromJson 往返正确', () {
      const value = MonthWeekDay(month: 6, week: 3, weekday: 7);
      final restored = MonthWeekDay.fromJson(value.toJson());
      expect(restored.month, 6);
      expect(restored.week, 3);
      expect(restored.weekday, 7);
    });

    test('QuarterDay toJson / fromJson 往返正确', () {
      const value = QuarterDay(quarter: 4, day: 90);
      final restored = QuarterDay.fromJson(value.toJson());
      expect(restored.quarter, 4);
      expect(restored.day, 90);
    });

    test('YearQuarterMonthDay toJson / fromJson 往返正确', () {
      const value = YearQuarterMonthDay(quarter: 2, monthInQuarter: 1, day: 4);
      final restored = YearQuarterMonthDay.fromJson(value.toJson());
      expect(restored.quarter, 2);
      expect(restored.monthInQuarter, 1);
      expect(restored.day, 4);
    });

    test('QuarterWeekDay toJson / fromJson 往返正确', () {
      const value = QuarterWeekDay(quarter: 3, week: 2, weekday: 4);
      final restored = QuarterWeekDay.fromJson(value.toJson());
      expect(restored.quarter, 3);
      expect(restored.week, 2);
      expect(restored.weekday, 4);
    });

    test('YearQuarterMonthWeekDay toJson / fromJson 往返正确', () {
      const value = YearQuarterMonthWeekDay(
        quarter: 1,
        monthInQuarter: 2,
        week: 3,
        weekday: 6,
      );
      final restored = YearQuarterMonthWeekDay.fromJson(value.toJson());
      expect(restored.quarter, 1);
      expect(restored.monthInQuarter, 2);
      expect(restored.week, 3);
      expect(restored.weekday, 6);
    });
  });
}