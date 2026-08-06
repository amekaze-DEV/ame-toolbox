import 'package:flutter_test/flutter_test.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/shift_calendar_controller.dart';
import 'package:shift_assistant_module/features/shift_assistant/utils/date_utils.dart';

void main() {
  group('ShiftCalendarController', () {
    test('defaults to today when no focused date provided', () {
      final controller = ShiftCalendarController();
      expect(isSameDay(controller.focusedDate, DateTime.now()), true);
    });

    test('initial focused date is normalized to date only', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 5, 14, 30),
      );
      expect(controller.focusedDate, DateTime(2026, 8, 5));
    });

    test('weekDays returns 7 days from Monday to Sunday', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 5),
      );
      final days = controller.weekDays;

      expect(days.length, 7);
      expect(days.first, DateTime(2026, 8, 3));
      expect(days.last, DateTime(2026, 8, 9));
    });

    test('previousWeek moves focused date back 7 days', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 5),
      );
      controller.previousWeek();

      expect(controller.focusedDate, DateTime(2026, 7, 29));
    });

    test('nextWeek moves focused date forward 7 days', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 5),
      );
      controller.nextWeek();

      expect(controller.focusedDate, DateTime(2026, 8, 12));
    });

    test('focusDate updates focused date and normalizes it', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 5),
      );
      controller.focusDate(DateTime(2026, 10, 1, 8, 0));

      expect(controller.focusedDate, DateTime(2026, 10, 1));
    });

    test('selectDate updates selected date', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 5),
      );
      controller.selectDate(DateTime(2026, 8, 7));

      expect(controller.selectedDate, DateTime(2026, 8, 7));
    });

    test('selectDate with same date does not notify repeatedly', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 5),
      );
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.selectDate(DateTime(2026, 8, 7));
      controller.selectDate(DateTime(2026, 8, 7, 12, 0));

      expect(notifyCount, 1);
    });

    test('goToToday updates focused date to today', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2020, 1, 1),
      );
      controller.goToToday();

      expect(isSameDay(controller.focusedDate, DateTime.now()), true);
    });

    test('clearSelection resets selected date', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 5),
      );
      controller.selectDate(DateTime(2026, 8, 7));
      controller.clearSelection();

      expect(controller.selectedDate, isNull);
    });

    test('focusedMonth returns first day of focused month', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 15),
      );
      expect(controller.focusedMonth, DateTime(2026, 8, 1));
    });

    test('monthWeekGrid returns complete weekly grid', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 1),
      );
      final grid = controller.monthWeekGrid;

      expect(grid.isNotEmpty, true);
      expect(grid.first.length, 7);
      expect(grid.first.first, DateTime(2026, 7, 27));
    });

    test('previousMonth moves to first day of previous month', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 15),
      );
      controller.previousMonth();

      expect(controller.focusedDate, DateTime(2026, 7, 1));
    });

    test('nextMonth moves to first day of next month', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 15),
      );
      controller.nextMonth();

      expect(controller.focusedDate, DateTime(2026, 9, 1));
    });

    test('focusMonth normalizes to first day of month', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 15),
      );
      controller.focusMonth(DateTime(2027, 12, 25));

      expect(controller.focusedDate, DateTime(2027, 12, 1));
    });

    test('goToToday updates focused month to current month', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2020, 1, 1),
      );
      controller.goToToday();

      expect(controller.focusedMonth.month, DateTime.now().month);
      expect(controller.focusedMonth.year, DateTime.now().year);
    });
  });
}
