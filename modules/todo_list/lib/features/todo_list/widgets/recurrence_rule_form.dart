import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/recurrence_pattern.dart';
import '../models/recurrence_rule.dart';
import '../models/recurrence_value_objects.dart';

/// 周期单位。
enum RecurrenceUnit {
  days('天'),
  weeks('周'),
  months('月'),
  quarters('季度'),
  years('年');

  const RecurrenceUnit(this.label);
  final String label;
}

/// 循环周期方式（对应 spec §2.7.2 五级菜单 14 种）。
enum RecurrenceType {
  everyXDays('第B天', RecurrenceUnit.days),
  weekly('第B天', RecurrenceUnit.weeks),
  monthlyDay('第B天', RecurrenceUnit.months),
  monthlyWeekDay('第B周 · 第C天', RecurrenceUnit.months),
  quarterlyDay('第B天', RecurrenceUnit.quarters),
  quarterlyMonthDay('第B月 · 第C天', RecurrenceUnit.quarters),
  quarterlyMonthWeekDay('第B月 · 第C周 · 第D天', RecurrenceUnit.quarters),
  yearlyDay('第B天', RecurrenceUnit.years),
  yearlyMonthDay('第B月 · 第C天', RecurrenceUnit.years),
  yearlyMonthWeekDay('第B月 · 第C周 · 第D天', RecurrenceUnit.years),
  yearlyQuarterDay('第B季度 · 第C天', RecurrenceUnit.years),
  yearlyQuarterMonthDay('第B季度 · 第C月 · 第D天', RecurrenceUnit.years),
  yearlyQuarterWeekDay('第B季度 · 第C周 · 第D天', RecurrenceUnit.years),
  yearlyQuarterMonthWeekDay(
    '第B季度 · 第C月 · 第D周 · 第E天',
    RecurrenceUnit.years,
  );

  const RecurrenceType(this.label, this.unit);
  final String label;
  final RecurrenceUnit unit;

  static List<RecurrenceType> of(RecurrenceUnit unit) =>
      RecurrenceType.values.where((t) => t.unit == unit).toList();
}

const _weekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

/// 参数表单字段定义。
class _FieldDef {
  const _FieldDef(this.label, this.min, this.max, [this.optionLabel]);

  final String label;
  final int min;
  final int max;
  final String Function(int)? optionLabel;
}

/// 单个循环规则的编辑表单（五级菜单层级）。
///
/// 返回构建好的 [RecurrenceRule]（含起始/终止时间），通过 [onSubmitted] 传出。
class RecurrenceRuleForm extends StatefulWidget {
  const RecurrenceRuleForm({
    super.key,
    this.initial,
    required this.onSubmitted,
  });

  /// 编辑已有规则时传入；新增时为空。
  final RecurrenceRule? initial;

  /// 点击「确定」时回调构建好的规则。
  final ValueChanged<RecurrenceRule> onSubmitted;

  @override
  State<RecurrenceRuleForm> createState() => _RecurrenceRuleFormState();
}

class _RecurrenceRuleFormState extends State<RecurrenceRuleForm> {
  // 循环周期：新增规则时两项均为空，需通过滚轮子面板赋值后才可保存。
  RecurrenceUnit? _unit;
  RecurrenceType? _type;
  int? _interval;
  bool _intervalIsCustom = false;

  // 参数行（每行为一组字段值；「第B天」类为单字段行）。
  List<List<int>> _rows = [];

  late DateTime _startDate;
  DateTime? _endDate;
  bool _infinite = true;

  @override
  void initState() {
    super.initState();
    final pattern = widget.initial?.pattern;
    if (pattern == null) {
      // 新增规则：循环周期两项留空，待用户通过滚轮赋值。
      _unit = null;
      _type = null;
      _interval = null;
      _intervalIsCustom = false;
    } else {
      _unit = _unitOf(pattern);
      _type = _typeOf(pattern) ?? RecurrenceType.of(_unit!).first;
      _interval = _intervalOf(pattern);
      _intervalIsCustom = _interval! > _unitMaxOf(_unit!);
      _rows = _rowsFromPattern(pattern, _type!);
    }
    final now = DateTime.now();
    _startDate = widget.initial?.startDate ?? DateTime(now.year, now.month, now.day);
    _endDate = widget.initial?.endDate;
    _infinite = _endDate == null;
  }

  /// 循环周期是否已完整设定（间隔 + 单位）。
  bool get _cycleComplete => _interval != null && _unit != null;

  /// 打开滚轮子面板选择循环周期；确认后回填。
  Future<void> _openCycleSheet() async {
    final result = await showDialog<_CycleSelection>(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        content: SizedBox(
          width: 320,
          child: _CyclePeriodPanel(
            initialUnit: _unit,
            initialInterval: _interval,
            initialIsCustom: _intervalIsCustom,
          ),
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _unit = result.unit;
      _interval = result.interval;
      _intervalIsCustom = result.isCustom;
      // 单位变化时重置定位方式与参数为默认值。
      if (_type == null || _type!.unit != result.unit) {
        _type = RecurrenceType.of(result.unit).first;
        _rows = _defaultRows(_type!);
      }
    });
  }

  static RecurrenceUnit _unitOf(RecurrencePattern? p) {
    return switch (p) {
      EveryXDaysPattern() => RecurrenceUnit.days,
      WeeklyPattern() => RecurrenceUnit.weeks,
      MonthlyDayPattern() || MonthlyWeekDayPattern() => RecurrenceUnit.months,
      QuarterlyDayPattern() ||
      QuarterlyMonthDayPattern() ||
      QuarterlyMonthWeekDayPattern() =>
        RecurrenceUnit.quarters,
      _ => RecurrenceUnit.years,
    };
  }

  static RecurrenceType? _typeOf(RecurrencePattern? p) {
    return switch (p) {
      EveryXDaysPattern() => RecurrenceType.everyXDays,
      WeeklyPattern() => RecurrenceType.weekly,
      MonthlyDayPattern() => RecurrenceType.monthlyDay,
      MonthlyWeekDayPattern() => RecurrenceType.monthlyWeekDay,
      QuarterlyDayPattern() => RecurrenceType.quarterlyDay,
      QuarterlyMonthDayPattern() => RecurrenceType.quarterlyMonthDay,
      QuarterlyMonthWeekDayPattern() => RecurrenceType.quarterlyMonthWeekDay,
      YearlyDayPattern() => RecurrenceType.yearlyDay,
      YearlyMonthDayPattern() => RecurrenceType.yearlyMonthDay,
      YearlyMonthWeekDayPattern() => RecurrenceType.yearlyMonthWeekDay,
      YearlyQuarterDayPattern() => RecurrenceType.yearlyQuarterDay,
      YearlyQuarterMonthDayPattern() => RecurrenceType.yearlyQuarterMonthDay,
      YearlyQuarterWeekDayPattern() => RecurrenceType.yearlyQuarterWeekDay,
      YearlyQuarterMonthWeekDayPattern() => RecurrenceType.yearlyQuarterMonthWeekDay,
      null => null,
    };
  }

  static int _intervalOf(RecurrencePattern? p) {
    return switch (p) {
      EveryXDaysPattern(interval: final i) => i,
      WeeklyPattern(interval: final i) => i,
      MonthlyDayPattern(interval: final i) => i,
      MonthlyWeekDayPattern(interval: final i) => i,
      QuarterlyDayPattern(interval: final i) => i,
      QuarterlyMonthDayPattern(interval: final i) => i,
      QuarterlyMonthWeekDayPattern(interval: final i) => i,
      YearlyDayPattern(interval: final i) => i,
      YearlyMonthDayPattern(interval: final i) => i,
      YearlyMonthWeekDayPattern(interval: final i) => i,
      YearlyQuarterDayPattern(interval: final i) => i,
      YearlyQuarterMonthDayPattern(interval: final i) => i,
      YearlyQuarterWeekDayPattern(interval: final i) => i,
      YearlyQuarterMonthWeekDayPattern(interval: final i) => i,
      null => 1,
    };
  }

  static Set<int>? _setOf(RecurrencePattern? p) => switch (p) {
        EveryXDaysPattern(days: final d) => d,
        WeeklyPattern(weekdays: final d) => d,
        MonthlyDayPattern(days: final d) => d,
        QuarterlyDayPattern(days: final d) => d,
        YearlyDayPattern(days: final d) => d,
        _ => null,
      };

  static List<List<int>>? _rowsOf(RecurrencePattern? p) => switch (p) {
        MonthlyWeekDayPattern(items: final l) => [for (final e in l) [e.week, e.weekday]],
        QuarterlyMonthDayPattern(items: final l) =>
          [for (final e in l) [e.monthInQuarter, e.day]],
        QuarterlyMonthWeekDayPattern(items: final l) =>
          [for (final e in l) [e.monthInQuarter, e.week, e.weekday]],
        YearlyMonthDayPattern(items: final l) => [for (final e in l) [e.month, e.day]],
        YearlyMonthWeekDayPattern(items: final l) =>
          [for (final e in l) [e.month, e.week, e.weekday]],
        YearlyQuarterDayPattern(items: final l) => [for (final e in l) [e.quarter, e.day]],
        YearlyQuarterMonthDayPattern(items: final l) =>
          [for (final e in l) [e.quarter, e.monthInQuarter, e.day]],
        YearlyQuarterWeekDayPattern(items: final l) =>
          [for (final e in l) [e.quarter, e.week, e.weekday]],
        YearlyQuarterMonthWeekDayPattern(items: final l) =>
          [for (final e in l) [e.quarter, e.monthInQuarter, e.week, e.weekday]],
        _ => null,
      };

  /// 是否为「第B天」类（单字段行，旧集合型 chips 编辑器）定位方式。
  static bool _isSetTypeOf(RecurrenceType type) => switch (type) {
        RecurrenceType.everyXDays ||
        RecurrenceType.weekly ||
        RecurrenceType.monthlyDay ||
        RecurrenceType.quarterlyDay ||
        RecurrenceType.yearlyDay =>
          true,
        _ => false,
      };

  /// 从规则加载参数行（「第B天」类集合转为单字段行，其余直接用行数据）。
  static List<List<int>> _rowsFromPattern(
    RecurrencePattern p,
    RecurrenceType type,
  ) {
    final setValue = _setOf(p);
    if (setValue != null) {
      return [for (final v in (setValue.toList()..sort())) [v]];
    }
    return _rowsOf(p) ?? _defaultRows(type);
  }

  /// 各定位方式的默认参数行。
  static List<List<int>> _defaultRows(RecurrenceType type) {
    if (_isSetTypeOf(type)) return [[1]];
    return switch (type) {
      RecurrenceType.monthlyWeekDay => [
          [1, 1],
        ],
      RecurrenceType.quarterlyMonthDay => [
          [1, 1],
        ],
      RecurrenceType.quarterlyMonthWeekDay => [
          [1, 1, 1],
        ],
      RecurrenceType.yearlyMonthDay => [
          [1, 1],
        ],
      RecurrenceType.yearlyMonthWeekDay => [
          [1, 1, 1],
        ],
      RecurrenceType.yearlyQuarterDay => [
          [1, 1],
        ],
      RecurrenceType.yearlyQuarterMonthDay => [
          [1, 1, 1],
        ],
      RecurrenceType.yearlyQuarterWeekDay => [
          [1, 1, 1],
        ],
      RecurrenceType.yearlyQuarterMonthWeekDay => [
          [1, 1, 1, 1],
        ],
      _ => const [],
    };
  }

  List<_FieldDef> get _fieldDefs => switch (_type) {
        RecurrenceType.everyXDays => [
            _FieldDef('第几天', 1, _interval ?? 1, (v) => '第$v天'),
          ],
        RecurrenceType.weekly => [
            _FieldDef('周几', 1, 7, (v) => _weekdayLabels[v - 1]),
          ],
        RecurrenceType.monthlyDay => [_FieldDef('几号', 1, 31, (v) => '$v号')],
        RecurrenceType.monthlyWeekDay => [
            _FieldDef('第几周', 1, 5, (v) => '第$v周'),
            _FieldDef('周几', 1, 7, (v) => _weekdayLabels[v - 1]),
          ],
        RecurrenceType.quarterlyDay => [
            _FieldDef('季度内第几天', 1, 90, (v) => '第$v天'),
          ],
        RecurrenceType.quarterlyMonthDay => [
            _FieldDef('季度内月份', 1, 3, (v) => '第$v月'),
            _FieldDef('几号', 1, 31, (v) => '$v号'),
          ],
        RecurrenceType.quarterlyMonthWeekDay => [
            _FieldDef('季度内月份', 1, 3, (v) => '第$v月'),
            _FieldDef('第几周', 1, 5, (v) => '第$v周'),
            _FieldDef('周几', 1, 7, (v) => _weekdayLabels[v - 1]),
          ],
        RecurrenceType.yearlyDay => [
            _FieldDef('年内第几天', 1, 366, (v) => '第$v天'),
          ],
        RecurrenceType.yearlyMonthDay => [
            _FieldDef('月份', 1, 12, (v) => '$v月'),
            _FieldDef('几号', 1, 31, (v) => '$v号'),
          ],
        RecurrenceType.yearlyMonthWeekDay => [
            _FieldDef('月份', 1, 12, (v) => '$v月'),
            _FieldDef('第几周', 1, 5, (v) => '第$v周'),
            _FieldDef('周几', 1, 7, (v) => _weekdayLabels[v - 1]),
          ],
        RecurrenceType.yearlyQuarterDay => [
            _FieldDef('季度', 1, 4, (v) => '第$v季度'),
            _FieldDef('季度内第几天', 1, 90, (v) => '第$v天'),
          ],
        RecurrenceType.yearlyQuarterMonthDay => [
            _FieldDef('季度', 1, 4, (v) => '第$v季度'),
            _FieldDef('季度内月份', 1, 3, (v) => '第$v月'),
            _FieldDef('几号', 1, 31, (v) => '$v号'),
          ],
        RecurrenceType.yearlyQuarterWeekDay => [
            _FieldDef('季度', 1, 4, (v) => '第$v季度'),
            _FieldDef('第几周', 1, 5, (v) => '第$v周'),
            _FieldDef('周几', 1, 7, (v) => _weekdayLabels[v - 1]),
          ],
        RecurrenceType.yearlyQuarterMonthWeekDay => [
            _FieldDef('季度', 1, 4, (v) => '第$v季度'),
            _FieldDef('季度内月份', 1, 3, (v) => '第$v月'),
            _FieldDef('第几周', 1, 5, (v) => '第$v周'),
            _FieldDef('周几', 1, 7, (v) => _weekdayLabels[v - 1]),
          ],
        _ => const [],
      };

  void _onTypeChanged(RecurrenceType type) {
    setState(() {
      _type = type;
      // 若 interval 超出该类型天数上限（每 A 天），钳制到 1。
      if (type == RecurrenceType.everyXDays && (_interval ?? 1) < 1) {
        _interval = 1;
      }
      _rows = _defaultRows(type);
    });
  }

  RecurrencePattern _buildPattern() {
    final interval = _interval!;
    // 「第B天」类：单字段行 → 集合。
    final daySet = {for (final r in _rows) r[0]};
    return switch (_type!) {
      RecurrenceType.everyXDays => EveryXDaysPattern(
          interval: interval,
          days: daySet,
        ),
      RecurrenceType.weekly => WeeklyPattern(
          interval: interval,
          weekdays: daySet,
        ),
      RecurrenceType.monthlyDay => MonthlyDayPattern(
          interval: interval,
          days: daySet,
        ),
      RecurrenceType.monthlyWeekDay => MonthlyWeekDayPattern(
          interval: interval,
          items: [for (final r in _rows) WeekDay(week: r[0], weekday: r[1])],
        ),
      RecurrenceType.quarterlyDay => QuarterlyDayPattern(
          interval: interval,
          days: daySet,
        ),
      RecurrenceType.quarterlyMonthDay => QuarterlyMonthDayPattern(
          interval: interval,
          items: [
            for (final r in _rows)
              MonthInQuarterDay(monthInQuarter: r[0], day: r[1]),
          ],
        ),
      RecurrenceType.quarterlyMonthWeekDay => QuarterlyMonthWeekDayPattern(
          interval: interval,
          items: [
            for (final r in _rows)
              MonthInQuarterWeekDay(monthInQuarter: r[0], week: r[1], weekday: r[2]),
          ],
        ),
      RecurrenceType.yearlyDay => YearlyDayPattern(
          interval: interval,
          days: daySet,
        ),
      RecurrenceType.yearlyMonthDay => YearlyMonthDayPattern(
          interval: interval,
          items: [for (final r in _rows) MonthDay(month: r[0], day: r[1])],
        ),
      RecurrenceType.yearlyMonthWeekDay => YearlyMonthWeekDayPattern(
          interval: interval,
          items: [
            for (final r in _rows)
              MonthWeekDay(month: r[0], week: r[1], weekday: r[2]),
          ],
        ),
      RecurrenceType.yearlyQuarterDay => YearlyQuarterDayPattern(
          interval: interval,
          items: [for (final r in _rows) QuarterDay(quarter: r[0], day: r[1])],
        ),
      RecurrenceType.yearlyQuarterMonthDay => YearlyQuarterMonthDayPattern(
          interval: interval,
          items: [
            for (final r in _rows)
              YearQuarterMonthDay(quarter: r[0], monthInQuarter: r[1], day: r[2]),
          ],
        ),
      RecurrenceType.yearlyQuarterWeekDay => YearlyQuarterWeekDayPattern(
          interval: interval,
          items: [
            for (final r in _rows)
              QuarterWeekDay(quarter: r[0], week: r[1], weekday: r[2]),
          ],
        ),
      RecurrenceType.yearlyQuarterMonthWeekDay => YearlyQuarterMonthWeekDayPattern(
          interval: interval,
          items: [
            for (final r in _rows)
              YearQuarterMonthWeekDay(
                quarter: r[0],
                monthInQuarter: r[1],
                week: r[2],
                weekday: r[3],
              ),
          ],
        ),
    };
  }

  Future<void> _pickDate({required bool isEnd}) async {
    final now = DateTime.now();
    final firstDate = isEnd ? _startDate : DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 10);
    final picked = await showDatePicker(
      context: context,
      initialDate: isEnd ? (_endDate ?? _startDate) : _startDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;
    setState(() {
      if (isEnd) {
        _endDate = picked;
      } else {
        _startDate = picked;
        // 终止时间早于新起始时间时重置。
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
          _infinite = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('循环周期', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openCycleSheet,
            icon: const Icon(Icons.repeat, size: 18),
            label: Text(
              _cycleComplete
                  ? '每 $_interval ${_unitLabelOf(_unit!)}'
                      '${_intervalIsCustom ? '（自定义）' : ''}'
                  : '未设定',
            ),
          ),
          if (!_cycleComplete) ...[
            const SizedBox(height: 4),
            Text(
              '请设置循环周期（间隔数量与周期单位）',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ],
          if (_type != null) ...[
            const SizedBox(height: 16),
            Text('定位方式', style: textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownMenu<RecurrenceType>(
              width: 320,
              initialSelection: _type,
              dropdownMenuEntries: [
                for (final t in RecurrenceType.of(_unit!))
                  DropdownMenuEntry<RecurrenceType>(value: t, label: t.label),
              ],
              onSelected: (t) {
                if (t != null) _onTypeChanged(t);
              },
            ),
            const SizedBox(height: 16),
            Text('参数', style: textTheme.titleSmall),
            const SizedBox(height: 4),
            _FieldsEditor(
              defs: _fieldDefs,
              rows: _rows,
              onChanged: (rows) => setState(() => _rows = rows),
            ),
          ],
          const Divider(height: 32),
          Text('起始时间', style: textTheme.titleSmall),
          const SizedBox(height: 4),
          _DateField(
            date: _startDate,
            onTap: () => _pickDate(isEnd: false),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('无限循环', style: textTheme.bodyLarge),
                    Text(
                      '关闭后可设定终止时间',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Md3Switch(
                value: _infinite,
                onChanged: (v) => setState(() {
                  _infinite = v;
                  if (v) _endDate = null;
                }),
              ),
            ],
          ),
          if (!_infinite) ...[
            const SizedBox(height: 8),
            _DateField(
              date: _endDate,
              onTap: () => _pickDate(isEnd: true),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AdaptiveButton(
                variant: AdaptiveButtonVariant.text,
                label: '取消',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              AdaptiveButton(
                label: '确定',
                // 循环周期未设定时禁止保存。
                onPressed: _cycleComplete ? _submit : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    widget.onSubmitted(RecurrenceRule(
      pattern: _buildPattern(),
      startDate: _startDate,
      endDate: _infinite ? null : _endDate,
    ));
    Navigator.of(context).pop();
  }
}

/// MD3 Switch 封装（复用底座）。
class Md3Switch extends StatelessWidget {
  const Md3Switch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).colorScheme.primary,
      inactiveThumbColor: Theme.of(context).colorScheme.outline,
      inactiveTrackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

/// 日期选择字段。
class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});

  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return OutlinedButton(
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 18),
          const SizedBox(width: 8),
          Text(
            date == null ? '选择日期' : _fmt(date!),
            style: textTheme.bodyLarge?.copyWith(
              color: date == null ? colorScheme.onSurfaceVariant : null,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// 值对象列表型参数编辑器：多行，每行由若干字段下拉组成，可增删。
class _FieldsEditor extends StatefulWidget {
  const _FieldsEditor({
    required this.defs,
    required this.rows,
    required this.onChanged,
  });

  final List<_FieldDef> defs;
  final List<List<int>> rows;
  final ValueChanged<List<List<int>>> onChanged;

  @override
  State<_FieldsEditor> createState() => _FieldsEditorState();
}

class _FieldsEditorState extends State<_FieldsEditor> {
  void _updateRow(int rowIndex, int fieldIndex, int value) {
    final rows = [
      for (var i = 0; i < widget.rows.length; i++)
        [
          for (var j = 0; j < widget.rows[i].length; j++)
            (i == rowIndex && j == fieldIndex) ? value : widget.rows[i][j],
        ],
    ];
    widget.onChanged(rows);
  }

  void _removeRow(int rowIndex) {
    final rows = [...widget.rows]..removeAt(rowIndex);
    widget.onChanged(rows);
  }

  void _addRow() {
    widget.onChanged([...widget.rows, [for (final d in widget.defs) d.min]]);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (var j = 0; j < widget.defs.length; j++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: DropdownMenu<int>(
                      width: 128,
                      label: Text(widget.defs[j].label),
                      initialSelection: widget.rows[i][j],
                      dropdownMenuEntries: [
                        for (var v = widget.defs[j].min; v <= widget.defs[j].max; v++)
                          DropdownMenuEntry<int>(
                            value: v,
                            label: widget.defs[j].optionLabel?.call(v) ?? '$v',
                          ),
                      ],
                      onSelected: (v) {
                        if (v != null) _updateRow(i, j, v);
                      },
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: '删除该组',
                  onPressed: () => _removeRow(i),
                  color: colorScheme.error,
                ),
              ],
            ),
          ),
        AdaptiveButton(
          variant: AdaptiveButtonVariant.outlined,
          icon: Icons.add,
          label: '添加一组',
          onPressed: _addRow,
        ),
      ],
    );
  }
}

/// 滚轮选项。
class _WheelOption {
  const _WheelOption(this.label, {this.isCustom = false});

  final String label;
  final bool isCustom;
}

/// 滚轮子面板的返回结果：循环周期（单位 + 间隔 + 是否自定义）。
typedef _CycleSelection = ({RecurrenceUnit unit, int interval, bool isCustom});

/// 各周期单位的间隔数量标准上限（超出即进入自定义）。
int _unitMaxOf(RecurrenceUnit u) => switch (u) {
      RecurrenceUnit.days => 31,
      RecurrenceUnit.weeks => 5,
      RecurrenceUnit.months => 12,
      RecurrenceUnit.quarters => 4,
      RecurrenceUnit.years => 10,
    };

/// 周期单位的显示名称。
String _unitLabelOf(RecurrenceUnit u) => switch (u) {
      RecurrenceUnit.days => '天',
      RecurrenceUnit.weeks => '周',
      RecurrenceUnit.months => '月',
      RecurrenceUnit.quarters => '季度',
      RecurrenceUnit.years => '年',
    };

/// 滚轮式选择器（基于 [CupertinoPicker]）。
///
/// 选项内容随周期单位变化（间隔滚轮：1 ~ 上限 + 末位「自定义」；
/// 单位滚轮：天/周/月/季度/年）。外层 `key` 驱动重建以重置到对应位置。
class _WheelSelector extends StatefulWidget {
  const _WheelSelector({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    this.width = 96,
  });

  final List<_WheelOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double width;

  @override
  State<_WheelSelector> createState() => _WheelSelectorState();
}

class _WheelSelectorState extends State<_WheelSelector> {
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.selectedIndex);
  }

  @override
  void didUpdateWidget(_WheelSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 仅在选项数量不变且索引合法时同步跳转；数量变化由外层 key 重建。
    if (widget.selectedIndex != oldWidget.selectedIndex &&
        widget.options.length == oldWidget.options.length &&
        widget.selectedIndex < widget.options.length) {
      _controller.jumpToItem(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: widget.width,
      height: 150,
      child: CupertinoPicker(
        scrollController: _controller,
        itemExtent: 30,
        selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
          background: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        onSelectedItemChanged: widget.onSelected,
        children: [
          for (final o in widget.options)
            Center(
              child: Text(
                o.label,
                style: textTheme.bodyLarge?.copyWith(
                  color: o.isCustom ? colorScheme.secondary : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 循环周期滚轮子面板：左侧间隔滚轮（随单位变化）+ 右侧单位滚轮。
///
/// 通过居中的 [AlertDialog] 展开，用户确认后以 [_CycleSelection] 返回。
class _CyclePeriodPanel extends StatefulWidget {
  const _CyclePeriodPanel({
    required this.initialUnit,
    required this.initialInterval,
    required this.initialIsCustom,
  });

  final RecurrenceUnit? initialUnit;
  final int? initialInterval;
  final bool initialIsCustom;

  @override
  State<_CyclePeriodPanel> createState() => _CyclePeriodPanelState();
}

class _CyclePeriodPanelState extends State<_CyclePeriodPanel> {
  late RecurrenceUnit _unit;
  late int _interval;
  late bool _isCustom;
  late final TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    _unit = widget.initialUnit ?? RecurrenceUnit.days;
    _interval = widget.initialInterval ?? 1;
    _isCustom = widget.initialIsCustom && widget.initialInterval != null;
    _customController = TextEditingController(text: '$_interval');
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  int get _max => _unitMaxOf(_unit);

  /// 间隔滚轮选项：1 ~ 上限 + 末位「自定义」。
  List<_WheelOption> get _numberOptions => [
        for (var v = 1; v <= _max; v++) _WheelOption('$v'),
        const _WheelOption('自定义', isCustom: true),
      ];

  int get _numberIndex {
    if (_isCustom || _interval > _max) return _max;
    return _interval - 1;
  }

  /// 单位滚轮选项。
  List<_WheelOption> get _unitOptions => [
        for (final u in RecurrenceUnit.values) _WheelOption(u.label),
      ];

  int get _unitIndex => RecurrenceUnit.values.indexOf(_unit);

  void _onUnitChanged(int index) {
    setState(() {
      _unit = RecurrenceUnit.values[index];
      if (_interval > _unitMaxOf(_unit)) {
        _isCustom = true;
      }
    });
  }

  void _onNumberChanged(int index) {
    final opt = _numberOptions[index];
    setState(() {
      if (opt.isCustom) {
        _isCustom = true;
        _customController.text = '$_interval';
      } else {
        _isCustom = false;
        _interval = index + 1;
      }
    });
  }

  void _onCustomChanged(String text) {
    final v = int.tryParse(text.trim());
    if (v != null && v > 0) {
      setState(() => _interval = v);
    }
  }

  void _confirm() {
    Navigator.of(context).pop((
      unit: _unit,
      interval: _interval,
      isCustom: _isCustom,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('循环周期', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧：间隔数字滚轮（选项随单位变化）
            _WheelSelector(
              key: ValueKey('number-$_unit'),
              width: 96,
              options: _numberOptions,
              selectedIndex: _numberIndex,
              onSelected: _onNumberChanged,
            ),
            const SizedBox(width: 8),
            // 右侧：周期单位滚轮
            _WheelSelector(
              key: const ValueKey('unit'),
              width: 96,
              options: _unitOptions,
              selectedIndex: _unitIndex,
              onSelected: _onUnitChanged,
            ),
          ],
        ),
        if (_isCustom) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _customController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '自定义间隔数量',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: _onCustomChanged,
          ),
        ],
        const SizedBox(height: 12),
        Text('每 $_interval ${_unitLabelOf(_unit)}',
            style: textTheme.bodyLarge),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AdaptiveButton(
              variant: AdaptiveButtonVariant.text,
              label: '取消',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            AdaptiveButton(
              label: '确定',
              onPressed: _confirm,
            ),
          ],
        ),
      ],
    );
  }
}