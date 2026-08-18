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

    test('initial view level is day', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 5),
      );
      expect(controller.viewLevel, CalendarViewLevel.day);
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

    test('goToToday updates focused date to today and resets to day view', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2020, 1, 1),
      );
      controller.showMonthPicker();
      controller.goToToday();

      expect(isSameDay(controller.focusedDate, DateTime.now()), true);
      expect(controller.viewLevel, CalendarViewLevel.day);
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

    // 视图层级测试

    test('showMonthPicker transitions to month view', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 5),
      );
      controller.showMonthPicker();

      expect(controller.viewLevel, CalendarViewLevel.month);
    });

    test('showMonthPicker does nothing when not in day view', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 5),
      );
      controller.showMonthPicker();
      controller.showMonthPicker(); // 再次调用不应切换

      expect(controller.viewLevel, CalendarViewLevel.month);
    });

    test('showYearPicker transitions to year view', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 5),
      );
      controller.showMonthPicker();
      controller.showYearPicker();

      expect(controller.viewLevel, CalendarViewLevel.year);
    });

    test('showDayView returns to day view from month view', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 5),
      );
      controller.showMonthPicker();
      controller.showDayView();

      expect(controller.viewLevel, CalendarViewLevel.day);
    });

    test('showDayView returns to day view from year view', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 5),
      );
      controller.showMonthPicker();
      controller.showYearPicker();
      controller.showDayView();

      expect(controller.viewLevel, CalendarViewLevel.day);
    });

    test('selectMonth goes back to day view and focuses the month', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 5),
      );
      controller.showMonthPicker();
      controller.selectMonth(3);

      expect(controller.viewLevel, CalendarViewLevel.day);
      expect(controller.focusedDate, DateTime(2026, 3, 1));
      expect(controller.selectedDate, isNull);
    });

    test('selectYear goes back to month view and focuses the year', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 5),
      );
      controller.showMonthPicker();
      controller.showYearPicker();
      controller.selectYear(2024);

      expect(controller.viewLevel, CalendarViewLevel.month);
      expect(controller.focusedDate, DateTime(2024, 8, 1));
    });

    test('previousUnit dispatches previousMonth in day view', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 15),
      );
      controller.previousUnit();

      expect(controller.focusedDate, DateTime(2026, 7, 1));
    });

    test('previousUnit dispatches previousYear in month view', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 15),
      );
      controller.showMonthPicker();
      controller.previousUnit();

      expect(controller.focusedDate, DateTime(2025, 8, 1));
    });

    test('previousUnit dispatches previousYearRange in year view', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 15),
      );
      controller.showMonthPicker();
      controller.showYearPicker();
      controller.previousUnit();

      // 2026 - 10 = 2016
      expect(controller.focusedDate, DateTime(2016, 8, 1));
    });

    test('nextUnit dispatches nextMonth in day view', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 15),
      );
      controller.nextUnit();

      expect(controller.focusedDate, DateTime(2026, 9, 1));
    });

    test('nextUnit dispatches nextYear in month view', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 15),
      );
      controller.showMonthPicker();
      controller.nextUnit();

      expect(controller.focusedDate, DateTime(2027, 8, 1));
    });

    test('nextUnit dispatches nextYearRange in year view', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 15),
      );
      controller.showMonthPicker();
      controller.showYearPicker();
      controller.nextUnit();

      // 2026 + 10 = 2036
      expect(controller.focusedDate, DateTime(2036, 8, 1));
    });

    test('yearRangeStart aligns to 10-year boundary', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 15),
      );
      // 2026 ~/ 10 * 10 = 2020
      expect(controller.yearRangeStart, 2020);
      expect(controller.yearRangeEnd, 2031);
    });

    test('yearRangeStart aligns down for early years', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2020, 1, 1),
      );
      // 2020 ~/ 10 * 10 = 2020
      expect(controller.yearRangeStart, 2020);
      expect(controller.yearRangeEnd, 2031);
    });

    test('yearRangeStart aligns for boundary year 0', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(0, 6, 15),
      );
      expect(controller.yearRangeStart, 0);
      expect(controller.yearRangeEnd, 11);
    });

    test('jumpToDate resets to day view and focuses date', () {
      final controller = ShiftCalendarController(
        focusedDate: DateTime(2026, 8, 15),
      );
      controller.showMonthPicker();
      controller.showYearPicker();
      controller.jumpToDate(DateTime(2025, 3, 10));

      expect(controller.viewLevel, CalendarViewLevel.day);
      expect(controller.focusedDate, DateTime(2025, 3, 10));
      expect(controller.selectedDate, DateTime(2025, 3, 10));
    });
  });
}