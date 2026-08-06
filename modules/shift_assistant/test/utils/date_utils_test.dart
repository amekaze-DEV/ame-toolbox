import 'package:flutter_test/flutter_test.dart';
import 'package:shift_assistant_module/features/shift_assistant/utils/date_utils.dart';

void main() {
  group('date utils', () {
    test('dateOnly removes time part', () {
      final original = DateTime(2026, 8, 5, 14, 30, 45, 123);
      final result = dateOnly(original);

      expect(result.year, 2026);
      expect(result.month, 8);
      expect(result.day, 5);
      expect(result.hour, 0);
      expect(result.minute, 0);
      expect(result.second, 0);
      expect(result.millisecond, 0);
    });

    test('weekStart returns Monday for mid-week date', () {
      // 2026-08-05 is Wednesday.
      expect(weekStart(DateTime(2026, 8, 5)), DateTime(2026, 8, 3));
    });

    test('weekStart returns same day for Monday', () {
      expect(weekStart(DateTime(2026, 8, 3)), DateTime(2026, 8, 3));
    });

    test('weekStart returns previous Monday for Sunday', () {
      // 2026-08-09 is Sunday.
      expect(weekStart(DateTime(2026, 8, 9)), DateTime(2026, 8, 3));
    });

    test('weekEnd returns Sunday', () {
      expect(weekEnd(DateTime(2026, 8, 5)), DateTime(2026, 8, 9));
    });

    test('daysOfWeek returns 7 days starting Monday', () {
      final days = daysOfWeek(DateTime(2026, 8, 5));

      expect(days.length, 7);
      expect(days.first, DateTime(2026, 8, 3));
      expect(days.last, DateTime(2026, 8, 9));
    });

    test('isSameDay ignores time', () {
      expect(
        isSameDay(
          DateTime(2026, 8, 5, 0, 0),
          DateTime(2026, 8, 5, 23, 59),
        ),
        true,
      );
      expect(
        isSameDay(
          DateTime(2026, 8, 5),
          DateTime(2026, 8, 6),
        ),
        false,
      );
    });

    test('formatWeekRange produces expected string', () {
      expect(formatWeekRange(DateTime(2026, 8, 5)), '8月3日 - 8月9日');
    });

    test('monthStart returns first day of month', () {
      expect(monthStart(DateTime(2026, 8, 15)), DateTime(2026, 8, 1));
    });

    test('daysInMonth returns correct day count', () {
      expect(daysInMonth(DateTime(2026, 8, 1)), 31);
      expect(daysInMonth(DateTime(2026, 2, 1)), 28);
      expect(daysInMonth(DateTime(2024, 2, 1)), 29);
    });

    test('monthWeeks starts from Monday before or on first day', () {
      // 2026-08-01 is Saturday, so first week starts from 2026-07-27 (Monday).
      final weeks = monthWeeks(DateTime(2026, 8, 15));
      expect(weeks.first.first, DateTime(2026, 7, 27));
      expect(weeks.last.last.month, 9);
    });

    test('monthWeeks covers all days of current month', () {
      final weeks = monthWeeks(DateTime(2026, 8, 1));
      final allDays = weeks.expand((w) => w).toList();
      final augustDays = allDays.where((d) => d.month == 8).toList();
      expect(augustDays.length, 31);
      expect(augustDays.first, DateTime(2026, 8, 1));
      expect(augustDays.last, DateTime(2026, 8, 31));
    });

    test('formatMonthYear produces expected string', () {
      expect(formatMonthYear(DateTime(2027, 8, 1)), '2027年8月');
    });
  });
}
