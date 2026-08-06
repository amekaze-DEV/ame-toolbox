import 'package:flutter/material.dart';

import '../utils/date_utils.dart';

/// 周历视图状态控制器。
///
/// 管理当前聚焦日期、当前周、选中日期等日历视图状态，不持有业务配置数据。
class ShiftCalendarController extends ChangeNotifier {
  ShiftCalendarController({DateTime? focusedDate})
      : _focusedDate = dateOnly(focusedDate ?? DateTime.now());

  DateTime _focusedDate;

  /// 当前聚焦日期，决定当前展示周。
  DateTime get focusedDate => _focusedDate;

  DateTime? _selectedDate;

  /// 用户选中的日期；为 null 表示未选中。
  DateTime? get selectedDate => _selectedDate;

  /// 当前聚焦周的起始日（周一）。
  DateTime get weekStartDate => weekStart(_focusedDate);

  /// 当前聚焦周的结束日（周日）。
  DateTime get weekEndDate => weekEnd(_focusedDate);

  /// 当前聚焦周的 7 天日期列表（周一至周日）。
  List<DateTime> get weekDays => daysOfWeek(_focusedDate);

  /// 当前聚焦月份的第一天。
  DateTime get focusedMonth => monthStart(_focusedDate);

  /// 当前聚焦月份的完整周列表。
  List<List<DateTime>> get monthWeekGrid => monthWeeks(_focusedDate);

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

  /// 切换到上一周。
  void previousWeek() {
    _focusedDate = _focusedDate.subtract(const Duration(days: 7));
    notifyListeners();
  }

  /// 切换到下一周。
  void nextWeek() {
    _focusedDate = _focusedDate.add(const Duration(days: 7));
    notifyListeners();
  }

  /// 回到今天所在周。
  void goToToday() {
    final today = dateOnly(DateTime.now());
    if (isSameDay(today, _focusedDate)) return;
    _focusedDate = today;
    notifyListeners();
  }

  /// 切换到上一个月。
  void previousMonth() {
    final previous = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
    _focusedDate = dateOnly(previous);
    notifyListeners();
  }

  /// 切换到下一个月。
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
}
