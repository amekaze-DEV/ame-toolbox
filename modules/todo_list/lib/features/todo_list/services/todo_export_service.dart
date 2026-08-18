import 'package:intl/intl.dart';

import '../models/recurrence_pattern.dart';
import '../models/recurrence_rule.dart';
import '../models/todo_item.dart';

/// 待办导出服务。
///
/// 生成 Markdown（.md）可编辑文档文本，供导出文件或复制至剪贴板。
class TodoExportService {
  const TodoExportService();

  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static const _weekdayNames = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  /// 生成 Markdown 文本（spec §4.6）。
  ///
  /// 结构：`# 待办清单` → `## 进行中` / `## 已完成`。
  String toMarkdown(List<TodoItem> items) {
    final buffer = StringBuffer()..writeln('# 待办清单');
    buffer.writeln();

    final active = items.where((i) => !i.isCompleted).toList();
    final done = items.where((i) => i.isCompleted).toList();

    buffer.writeln('## 进行中');
    if (active.isEmpty) {
      buffer.writeln('- 暂无');
    } else {
      for (final item in active) {
        buffer.writeln('- ${_activeLine(item)}');
      }
    }
    buffer.writeln();

    buffer.writeln('## 已完成');
    if (done.isEmpty) {
      buffer.writeln('- 暂无');
    } else {
      for (final item in done) {
        buffer.writeln('- [x] ${_doneLine(item)}');
      }
    }

    return buffer.toString().trimRight();
  }

  String _activeLine(TodoItem item) {
    final meta = <String>[
      item.priority.displayName,
      if (item.recurrenceRules.isNotEmpty)
        '循环：${item.recurrenceRules.map(_describeRule).join('; ')}',
      if (item.dueDate != null) '${_dateFormat.format(item.dueDate!)} 截止',
    ].where((s) => s.isNotEmpty);
    return '[ ] ${item.title}${meta.isEmpty ? '' : '（${meta.join('，')}）'}';
  }

  String _doneLine(TodoItem item) {
    final when = item.completedAt ?? item.updatedAt;
    return '${item.title}（${_dateFormat.format(when)}）';
  }

  String _describeRule(RecurrenceRule rule) => switch (rule.pattern) {
        EveryXDaysPattern p => '${_unit(p.interval, '天')}的第${_listInt(p.days)}天',
        WeeklyPattern p => '${_unit(p.interval, '周')}的${_listIntWeekday(p.weekdays)}',
        MonthlyDayPattern p => '${_unit(p.interval, '月')}的${_listInt(p.days)}号',
        MonthlyWeekDayPattern p =>
          '${_unit(p.interval, '月')}的${p.items.map((e) => _weekDay(e.week, e.weekday)).join('、')}',
        QuarterlyDayPattern p =>
          '${_unit(p.interval, '季度')}的第${_listInt(p.days)}天',
        QuarterlyMonthDayPattern p =>
          '${_unit(p.interval, '季度')}的${p.items.map((e) => '第${e.monthInQuarter}月${e.day}号').join('、')}',
        QuarterlyMonthWeekDayPattern p =>
          '${_unit(p.interval, '季度')}的${p.items.map((e) => '第${e.monthInQuarter}月${_weekDay(e.week, e.weekday)}').join('、')}',
        YearlyDayPattern p => '${_unit(p.interval, '年')}的第${_listInt(p.days)}天',
        YearlyMonthDayPattern p =>
          '${_unit(p.interval, '年')}的${p.items.map((e) => '${e.month}月${e.day}号').join('、')}',
        YearlyMonthWeekDayPattern p =>
          '${_unit(p.interval, '年')}的${p.items.map((e) => '${e.month}月${_weekDay(e.week, e.weekday)}').join('、')}',
        YearlyQuarterDayPattern p =>
          '${_unit(p.interval, '年')}的${p.items.map((e) => '第${e.quarter}季度第${e.day}天').join('、')}',
        YearlyQuarterMonthDayPattern p =>
          '${_unit(p.interval, '年')}的${p.items.map((e) => '第${e.quarter}季度第${e.monthInQuarter}月${e.day}号').join('、')}',
        YearlyQuarterWeekDayPattern p =>
          '${_unit(p.interval, '年')}的${p.items.map((e) => '第${e.quarter}季度${_weekDay(e.week, e.weekday)}').join('、')}',
        YearlyQuarterMonthWeekDayPattern p =>
          '${_unit(p.interval, '年')}的${p.items.map((e) => '第${e.quarter}季度第${e.monthInQuarter}月${_weekDay(e.week, e.weekday)}').join('、')}',
      };

  /// interval == 1 时省略数字（如"每周"），否则带数字（如"每2周"）。
  static String _unit(int interval, String unit) =>
      interval <= 1 ? '每$unit' : '每$interval$unit';

  static String _listInt(Set<int> values) {
    final list = values.toList()..sort();
    return list.join('、');
  }

  static String _listIntWeekday(Set<int> values) {
    final list = values.toList()..sort();
    return list.map(_weekdayNames.elementAt).join('、');
  }

  static String _weekDay(int week, int weekday) {
    final day = weekday >= 1 && weekday <= 7 ? _weekdayNames[weekday] : '';
    return week >= 1 ? '第$week周$day' : day;
  }
}