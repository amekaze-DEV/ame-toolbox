import 'package:flutter/material.dart';

import '../utils/date_utils.dart';

/// 日历视图层级。
enum CalendarViewLevel {
  /// 日视图：按日展示日历，标题为"X年X月"。
  day,

  /// 月视图：3×4 月份网格，标题为"X年"。
  month,

  /// 年视图：3×4 年份网格，标题为"XXXX-XXXX年"。
  year,
}

/// 日历视图状态控制器。
///
/// 管理当前聚焦日期、选中日期、视图层级，以及各层级间的导航方法。
class ShiftCalendarController extends ChangeNotifier {
  ShiftCalendarController({DateTime? focusedDate})
      : _focusedDate = dateOnly(focusedDate ?? DateTime.now());

  DateTime _focusedDate;

  /// 当前聚焦日期，决定当前展示的月份/年份。
  DateTime get focusedDate => _focusedDate;

  DateTime? _selectedDate;

  /// 用户选中的日期；为 null 表示未选中。
  DateTime? get selectedDate => _selectedDate;

  CalendarViewLevel _viewLevel = CalendarViewLevel.day;

  /// 当前视图层级。
  CalendarViewLevel get viewLevel => _viewLevel;

  /// 当前聚焦月份的第一天。
  DateTime get focusedMonth => monthStart(_focusedDate);

  /// 当前聚焦月份的完整周列表。
  List<List<DateTime>> get monthWeekGrid => monthWeeks(_focusedDate);

  /// 年份窗口起始年（以 10 整除对齐，取本十年起点）。
  int get yearRangeStart => (_focusedDate.year ~/ 10) * 10;

  /// 年份窗口结束年。
  int get yearRangeEnd => yearRangeStart + 11;

  /// 聚焦到指定日期，所在周同步切换。
  void focusDate(DateTime date) {
    final normalized = dateOnly(date);
    if (isSameDay(normalized, _focusedDate)) return;
    _focusedDate = normalized;
    notifyListeners();
  }

  /// 选中指定日期。
  void selectDate(DateTime date) {
    final normalized = dateOnly(date);
    final selected = _selectedDate;
    if (selected != null && isSameDay(normalized, selected)) return;
    _selectedDate = normalized;
    notifyListeners();
  }

  /// 取消选中。
  void clearSelection() {
    if (_selectedDate == null) return;
    _selectedDate = null;
    notifyListeners();
  }

  /// 返回日视图并聚焦到今天。
  void goToToday() {
    final wasDayView = _viewLevel == CalendarViewLevel.day;
    _viewLevel = CalendarViewLevel.day;
    final today = dateOnly(DateTime.now());
    if (!wasDayView || !isSameDay(today, _focusedDate)) {
      _focusedDate = today;
    }
    notifyListeners();
  }

  /// 切换到上一个月（日视图）。
  void previousMonth() {
    final previous = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
    _focusedDate = dateOnly(previous);
    notifyListeners();
  }

  /// 切换到下一个月（日视图）。
  void nextMonth() {
    final next = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
    _focusedDate = dateOnly(next);
    notifyListeners();
  }

  /// 聚焦到指定月份。
  void focusMonth(DateTime month) {
    final normalized = dateOnly(DateTime(month.year, month.month, 1));
    if (isSameDay(normalized, focusedMonth)) return;
    _focusedDate = normalized;
    notifyListeners();
  }

  /// 按当前层级向前导航（上个月/上一年/上一个年份窗口）。
  void previousUnit() {
    switch (_viewLevel) {
      case CalendarViewLevel.day:
        previousMonth();
        break;
      case CalendarViewLevel.month:
        _focusedDate =
            dateOnly(DateTime(_focusedDate.year - 1, _focusedDate.month, 1));
        notifyListeners();
        break;
      case CalendarViewLevel.year:
        _focusedDate =
            dateOnly(DateTime(_focusedDate.year - 10, _focusedDate.month, 1));
        notifyListeners();
        break;
    }
  }

  /// 按当前层级向后导航（下个月/下一年/下一个年份窗口）。
  void nextUnit() {
    switch (_viewLevel) {
      case CalendarViewLevel.day:
        nextMonth();
        break;
      case CalendarViewLevel.month:
        _focusedDate =
            dateOnly(DateTime(_focusedDate.year + 1, _focusedDate.month, 1));
        notifyListeners();
        break;
      case CalendarViewLevel.year:
        _focusedDate =
            dateOnly(DateTime(_focusedDate.year + 10, _focusedDate.month, 1));
        notifyListeners();
        break;
    }
  }

  /// 从日视图进入月视图（月份选择器）。
  void showMonthPicker() {
    if (_viewLevel != CalendarViewLevel.day) return;
    _viewLevel = CalendarViewLevel.month;
    notifyListeners();
  }

  /// 从月视图进入年视图（年份选择器）。
  void showYearPicker() {
    if (_viewLevel != CalendarViewLevel.month) return;
    _viewLevel = CalendarViewLevel.year;
    notifyListeners();
  }

  /// 返回日视图。
  void showDayView() {
    if (_viewLevel == CalendarViewLevel.day) return;
    _viewLevel = CalendarViewLevel.day;
    notifyListeners();
  }

  /// 选择月份，回日视图并聚焦该月。
  void selectMonth(int month) {
    _focusedDate = dateOnly(DateTime(_focusedDate.year, month, 1));
    _viewLevel = CalendarViewLevel.day;
    _selectedDate = null;
    notifyListeners();
  }

  /// 选择年份，回月视图并聚焦该年。
  void selectYear(int year) {
    _focusedDate = dateOnly(DateTime(year, _focusedDate.month, 1));
    _viewLevel = CalendarViewLevel.month;
    notifyListeners();
  }

  /// 日期转跳：回日视图并聚焦选中日期。
  void jumpToDate(DateTime date) {
    final normalized = dateOnly(date);
    _viewLevel = CalendarViewLevel.day;
    _focusedDate = normalized;
    _selectedDate = normalized;
    notifyListeners();
  }
}