import 'package:flutter/material.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/recurrence_pattern.dart';
import '../models/recurrence_rule.dart';
import '../models/recurrence_value_objects.dart';
import 'recurrence_rule_form.dart';

/// 循环规则设定器。
///
/// 展示已有规则列表（支持删除/编辑），并可新增规则。
/// 规则通过 [onChanged] 回调给父级。
class RecurrenceRuleEditor extends StatelessWidget {
  const RecurrenceRuleEditor({
    super.key,
    required this.rules,
    required this.onChanged,
  });

  final List<RecurrenceRule> rules;
  final ValueChanged<List<RecurrenceRule>> onChanged;

  void _openForm(BuildContext context, {RecurrenceRule? initial}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(initial == null ? '新增循环规则' : '编辑循环规则'),
        content: SizedBox(
          width: 460,
          child: RecurrenceRuleForm(
            initial: initial,
            onSubmitted: (rule) {
              if (initial == null) {
                onChanged([...rules, rule]);
              } else {
                onChanged([
                  for (final r in rules) identical(r, initial) ? rule : r,
                ]);
              }
            },
          ),
        ),
        actions: const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('循环规则', style: textTheme.titleSmall),
            const Spacer(),
            AdaptiveButton(
              variant: AdaptiveButtonVariant.outlined,
              icon: Icons.add,
              label: '新增规则',
              onPressed: () => _openForm(context),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (rules.isEmpty)
          Text(
            '未设置循环规则（一次性事项）',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final rule in rules)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.repeat),
                title: Text(describeRule(rule)),
                subtitle: Text(
                  '自 ${_fmt(rule.startDate)}'
                  '${rule.endDate == null ? ' · 无限循环' : ' 至 ${_fmt(rule.endDate!)}'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AdaptiveIconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: '编辑',
                      onPressed: () => _openForm(context, initial: rule),
                    ),
                    AdaptiveIconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: '删除',
                      onPressed: () => onChanged(
                        rules.where((r) => !identical(r, rule)).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// 生成循环规则的人类可读描述（用于列表展示）。
String describeRule(RecurrenceRule rule) {
  final p = rule.pattern;
  final detail = switch (p) {
    EveryXDaysPattern(interval: final i, days: final d) =>
      '每$i天，第${_fmtList(d)}天',
    WeeklyPattern(interval: final i, weekdays: final d) =>
      '每$i周，${_fmtList(d, weekday: true)}',
    MonthlyDayPattern(interval: final i, days: final d) => '每$i月，${_fmtList(d)}号',
    MonthlyWeekDayPattern(interval: final i, items: final l) =>
      '每$i月，${_weekDayList(l)}',
    QuarterlyDayPattern(interval: final i, days: final d) =>
      '每$i季度，第${_fmtList(d)}天',
    QuarterlyMonthDayPattern(interval: final i, items: final l) =>
      '每$i季度，${_monthInQuarterDayList(l)}',
    QuarterlyMonthWeekDayPattern(interval: final i, items: final l) =>
      '每$i季度，${_monthInQuarterWeekDayList(l)}',
    YearlyDayPattern(interval: final i, days: final d) => '每$i年，第${_fmtList(d)}天',
    YearlyMonthDayPattern(interval: final i, items: final l) =>
      '每$i年，${_monthDayList(l)}',
    YearlyMonthWeekDayPattern(interval: final i, items: final l) =>
      '每$i年，${_monthWeekDayList(l)}',
    YearlyQuarterDayPattern(interval: final i, items: final l) =>
      '每$i年，${_quarterDayList(l)}',
    YearlyQuarterMonthDayPattern(interval: final i, items: final l) =>
      '每$i年，${_yearQuarterMonthDayList(l)}',
    YearlyQuarterWeekDayPattern(interval: final i, items: final l) =>
      '每$i年，${_quarterWeekDayList(l)}',
    YearlyQuarterMonthWeekDayPattern(interval: final i, items: final l) =>
      '每$i年，${_yearQuarterMonthWeekDayList(l)}',
  };

  return detail;
}

const _weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

List<int> _sorted(Set<int> s) => s.toList()..sort();

String _join(List<String> parts) => parts.join('、');

String _fmtList(Set<int> values, {bool weekday = false}) =>
    _join([for (final v in _sorted(values)) weekday ? _weekdayNames[v - 1] : '$v']);

String _weekDayList(List<WeekDay> l) => _join([
      for (final e in l) '第${e.week}周${_weekdayNames[e.weekday - 1]}',
    ]);

String _monthInQuarterDayList(List<MonthInQuarterDay> l) => _join([
      for (final e in l) '第${e.monthInQuarter}月${e.day}号',
    ]);

String _monthInQuarterWeekDayList(List<MonthInQuarterWeekDay> l) => _join([
      for (final e in l)
        '第${e.monthInQuarter}月第${e.week}周${_weekdayNames[e.weekday - 1]}',
    ]);

String _monthDayList(List<MonthDay> l) => _join([
      for (final e in l) '${e.month}月${e.day}号',
    ]);

String _monthWeekDayList(List<MonthWeekDay> l) => _join([
      for (final e in l)
        '${e.month}月第${e.week}周${_weekdayNames[e.weekday - 1]}',
    ]);

String _quarterDayList(List<QuarterDay> l) => _join([
      for (final e in l) '第${e.quarter}季度第${e.day}天',
    ]);

String _yearQuarterMonthDayList(List<YearQuarterMonthDay> l) => _join([
      for (final e in l) '第${e.quarter}季度第${e.monthInQuarter}月${e.day}号',
    ]);

String _quarterWeekDayList(List<QuarterWeekDay> l) => _join([
      for (final e in l)
        '第${e.quarter}季度第${e.week}周${_weekdayNames[e.weekday - 1]}',
    ]);

String _yearQuarterMonthWeekDayList(List<YearQuarterMonthWeekDay> l) => _join([
      for (final e in l)
        '第${e.quarter}季度第${e.monthInQuarter}月第${e.week}周'
        '${_weekdayNames[e.weekday - 1]}',
    ]);