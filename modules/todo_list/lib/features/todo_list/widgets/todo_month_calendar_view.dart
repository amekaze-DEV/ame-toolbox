import 'package:flutter/material.dart';
import 'package:flutter_mdi_icons/flutter_mdi_icons.dart';
import 'package:intl/intl.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/holiday_info.dart';
import '../models/todo_priority.dart';
import 'todo_item_tile.dart' show todoPriorityColor;

/// 日历视图层级。
///
/// 待办模块日历为受控组件，层级状态由页面持有并通过 [viewLevel] 传入。
enum CalendarViewLevel {
  /// 日视图（默认）：月历网格，标题为“yyyy年M月”。
  day,

  /// 月视图：3×4 月份选择网格，标题为“yyyy年”。
  month,

  /// 年视图：3×4 年份选择网格（本十年窗口），标题为“windowStart-windowEnd年”。
  year,
}

/// 月/年选择网格的基准宽度。
///
/// 网格以该宽度布局（含内边距），可用空间不足时由 [FittedBox] 整体等比缩放，
/// 保证任意窗口长宽比下完整显示、无需滚动。
const double _gridBaseWidth = 400;

/// 网格水平内边距（两侧各）。
const double _gridHorizontalPadding = 24;

/// 网格垂直内边距（上下各）。
const double _gridVerticalPadding = 32;

/// 网格行间距。
const double _gridRowGap = 12;

/// 单元格高度（固定值）。
///
/// 使用固定高度而非 [AspectRatio]：AspectRatio 的 intrinsic 高度由传入宽度推导，
/// 在宽窗口下会被视口宽度撑高并产生滚动条，固定高度使 intrinsic 恒定。
const double _gridCellHeight = 78;

/// 网格内容高度（4 行 + 3 行间距，不含内外边距）。
final double _gridContentHeight = 4 * _gridCellHeight + 3 * _gridRowGap;

/// 单日附加展示信息（农历 / 节气 / 节日 / 节假日调休）。
///
/// 由父组件计算后以查找表形式传入日历视图，保持日历为纯展示组件。
class TodoDayExtra {
  /// 农历日期字符串，如“七月初一”。
  final String lunarDate;

  /// 节气，如“立秋”。为 null 表示当日无节气。
  final String? solarTerm;

  /// 公历节日列表，如“国庆节”、“母亲节”。空列表表示当日无节日。
  final List<String> solarFestivals;

  /// 节假日/调休信息。为 null 表示当日无特殊节假日。
  final HolidayInfo? holiday;

  const TodoDayExtra({
    this.lunarDate = '',
    this.solarTerm,
    this.solarFestivals = const [],
    this.holiday,
  });
}

/// 类日历月视图（受控组件）。
///
/// 支持日/月/年三级视图：日视图展示当前月份，支持翻月、回到今天、选中日期、
/// 有待办日期标记；月/年视图展示 3×4 选择网格。
/// 每个日期格显示农历/节气/节假日与调休情况（休/班）。
/// 状态由父组件持有，通过 [displayMonth] / [selectedDate] / [viewLevel] 传入。
class TodoMonthCalendarView extends StatelessWidget {
  const TodoMonthCalendarView({
    super.key,
    required this.displayMonth,
    required this.selectedDate,
    required this.today,
    required this.markedDates,
    required this.dayExtras,
    required this.onSelectDate,
    required this.viewLevel,
    required this.onTitleTap,
    required this.onMonthSelected,
    required this.onYearSelected,
    required this.onPreviousUnit,
    required this.onNextUnit,
    required this.onToday,
    this.onDateJump,
  });

  final DateTime displayMonth;
  final DateTime selectedDate;
  final DateTime today;

  /// 当月每天待办的最高优先级（用于日期下方色点颜色）。
  final Map<DateTime, TodoPriority> markedDates;

  /// 当月每天的附加展示信息查找表（key 为日期，时间部分恒为 00:00:00）。
  final Map<DateTime, TodoDayExtra> dayExtras;

  final ValueChanged<DateTime> onSelectDate;

  /// 当前视图层级。
  final CalendarViewLevel viewLevel;

  /// 标题点击：日→月、月→年、年无操作。
  final VoidCallback onTitleTap;

  /// 月份格选中（返回日视图并聚焦该月）。
  final ValueChanged<int> onMonthSelected;

  /// 年份格选中（返回月视图并聚焦该年）。
  final ValueChanged<int> onYearSelected;

  /// 层级感知的向前导航：day ±1 月、month ±1 年、year ±10 年。
  final VoidCallback onPreviousUnit;

  /// 层级感知的向后导航：day ±1 月、month ±1 年、year ±10 年。
  final VoidCallback onNextUnit;

  /// 「今天」：任意层级回日视图并聚焦今天。
  final VoidCallback onToday;

  /// 日期转跳回调：用户在日期选择器中选中日期后触发。
  ///
  /// 为 null 时不显示「日期转跳」按钮。
  final ValueChanged<DateTime>? onDateJump;

  static const _weekLabels = ['一', '二', '三', '四', '五', '六', '日'];

  /// 年视图年份窗口起始年（以 10 整除对齐，取本十年起点）。
  int get _yearRangeStart => (displayMonth.year ~/ 10) * 10;

  /// 年视图年份窗口结束年。
  int get _yearRangeEnd => _yearRangeStart + 11;

  /// 根据当前层级生成标题文本。
  String get _titleText {
    switch (viewLevel) {
      case CalendarViewLevel.day:
        return DateFormat('yyyy年M月').format(displayMonth);
      case CalendarViewLevel.month:
        return '${displayMonth.year}年';
      case CalendarViewLevel.year:
        return '$_yearRangeStart-$_yearRangeEnd年';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (viewLevel != CalendarViewLevel.day) {
      // 月/年视图：固定工具栏 + 自适应缩放网格。
      //
      // 待办页面布局下日历可能处于两种约束：
      // - 高度有界（横屏被 Row/Expanded 约束）：工具栏固定，剩余空间由
      //   Center + FittedBox 在真实可用空间内等比缩放网格（同倒班助手做法），
      //   保证完整显示、无溢出、无滚动。
      // - 高度无界（竖屏是外层 Column 的非 Flex 子项）：网格按内容自然高度
      //   布局，宽度不足时由 FittedBox 等比缩放，不引入额外滚动容器。
      return LayoutBuilder(
        builder: (context, constraints) {
          final header = _buildHeader(context, colorScheme, textTheme);
          if (constraints.hasBoundedHeight) {
            return Column(
              children: [
                header,
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _gridBox(viewLevel),
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              header,
              const SizedBox(height: 8),
              Center(
                heightFactor: 1.0,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _gridBox(viewLevel),
                ),
              ),
            ],
          );
        },
      );
    }

    final year = displayMonth.year;
    final month = displayMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1; // 周一开头
    final total = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;
    // 网格起始日期：含上月补位（月初空格显示上月日期）。
    final gridStart = firstDay.subtract(Duration(days: leadingBlanks));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, colorScheme, textTheme),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final label in _weekLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 48,
          ),
          itemCount: total,
          itemBuilder: (context, index) {
            // 网格首日起顺序铺满，覆盖上月补位 / 本月 / 下月补位。
            final date = gridStart.add(Duration(days: index));
            return _buildDayCell(
              context,
              colorScheme,
              textTheme,
              date,
              dayExtras[date],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // 箭头 tooltip 随层级变化。
    final prevTooltip = switch (viewLevel) {
      CalendarViewLevel.day => '上一月',
      CalendarViewLevel.month => '上一年',
      CalendarViewLevel.year => '上一个十年窗口',
    };
    final nextTooltip = switch (viewLevel) {
      CalendarViewLevel.day => '下一月',
      CalendarViewLevel.month => '下一年',
      CalendarViewLevel.year => '下一个十年窗口',
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        // 横屏窄列时隐藏文字按钮，避免 Row 溢出：
        // 「今天」所需宽度较小优先保留，「日期转跳」较宽、空间不足时先隐藏。
        final showToday = constraints.maxWidth >= 220;
        final showJump =
            constraints.maxWidth >= 320 && onDateJump != null;
        // 布局：`< 标题 >` 整体靠左，`日期转跳`/`今天` 靠右。
        return Row(
          children: [
            AdaptiveIconButton(
              icon: const Icon(Mdi.chevronLeft),
              tooltip: prevTooltip,
              onPressed: onPreviousUnit,
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: GestureDetector(
                  // 标题可点击：日→月、月→年、年无操作。
                  onTap: onTitleTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      _titleText,
                      style: textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            ),
            AdaptiveIconButton(
              icon: const Icon(Mdi.chevronRight),
              tooltip: nextTooltip,
              onPressed: onNextUnit,
            ),
            const Spacer(),
            if (showJump)
              AdaptiveButton(
                variant: AdaptiveButtonVariant.text,
                label: '日期转跳',
                onPressed: () => _openDatePicker(context),
              ),
            if (showToday)
              AdaptiveButton(
                variant: AdaptiveButtonVariant.text,
                label: '今天',
                onPressed: onToday,
              ),
          ],
        );
      },
    );
  }

  /// 月/年选择网格的固定基准尺寸容器（含内外边距）。
  ///
  /// 网格以基准尺寸布局，由调用方的 [FittedBox] 在可用空间不足时整体等比缩放。
  Widget _gridBox(CalendarViewLevel level) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _gridHorizontalPadding,
        vertical: _gridVerticalPadding,
      ),
      child: SizedBox(
        width: _gridBaseWidth,
        height: _gridContentHeight,
        child: level == CalendarViewLevel.month
            ? _MonthPickerGrid(
                focusedYear: displayMonth.year,
                focusedMonth: displayMonth.month,
                onMonthSelected: onMonthSelected,
              )
            : _YearPickerGrid(
                yearRangeStart: _yearRangeStart,
                yearRangeEnd: _yearRangeEnd,
                focusedYear: displayMonth.year,
                onYearSelected: onYearSelected,
              ),
      ),
    );
  }

  /// 弹出日期选择器，选中后触发 [onDateJump]。
  Future<void> _openDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onDateJump?.call(picked);
  }

  Widget _buildDayCell(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    DateTime date,
    TodoDayExtra? extra,
  ) {
    final isSelected =
        date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    // 当日待办最高优先级（无待办为 null，不显示色点）。
    final markPriority = markedDates[date];

    final bgColor = isSelected
        ? colorScheme.primaryContainer
        : isToday
            ? colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent;

    // 附加标记：公历节日 > 节气 > 农历日期。
    final markerText = _markerText(extra);
    final markerColor = _markerColor(colorScheme, extra);
    // 公历日期文字：休/班用节假日色，其余按选中/今日/普通区分。
    final labelColor = _labelColor(
      colorScheme,
      extra,
      isSelected,
      isToday,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onSelectDate(date),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(color: colorScheme.primary)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _dayLabel(extra, date),
                  style: textTheme.bodyMedium?.copyWith(
                    height: 1.1,
                    color: labelColor,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (markerText != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        markerText,
                        maxLines: 1,
                        style: textTheme.labelSmall?.copyWith(
                          height: 1.0,
                          fontSize: 9,
                          color: markerColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (markPriority != null)
              Positioned(
                bottom: 4,
                child: Container(
                  key: ValueKey(
                    'todo_mark_${date.year}_${date.month}_${date.day}',
                  ),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: todoPriorityColor(markPriority, colorScheme),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 日期格子的附加标记文本：公历节日优先，其次节气，再次农历日期。
  static String? _markerText(TodoDayExtra? extra) {
    if (extra == null) return null;
    if (extra.solarFestivals.isNotEmpty) {
      return extra.solarFestivals.first;
    }
    if (extra.solarTerm != null && extra.solarTerm!.isNotEmpty) {
      return extra.solarTerm;
    }
    if (extra.lunarDate.isNotEmpty) {
      return extra.lunarDate;
    }
    return null;
  }

  /// 生成日期格子顶部文本：法定假日尾缀“休”，调休工作日尾缀“班”。
  static String _dayLabel(TodoDayExtra? extra, DateTime date) {
    final holiday = extra?.holiday;
    if (holiday != null && holiday.isHoliday) return '${date.day}休';
    if (holiday != null && holiday.isWorkday) return '${date.day}班';
    return '${date.day}';
  }

  /// 公历日期文字颜色：休/班用节假日标记色突出，其余按选中/今日区分。
  static Color _labelColor(
    ColorScheme colorScheme,
    TodoDayExtra? extra,
    bool isSelected,
    bool isToday,
  ) {
    final holiday = extra?.holiday;
    if (holiday != null && (holiday.isHoliday || holiday.isWorkday)) {
      return colorScheme.error;
    }
    if (isSelected) return colorScheme.onPrimaryContainer;
    if (isToday) return colorScheme.primary;
    return colorScheme.onSurface;
  }

  /// 附加标记的颜色：节假日/调休用 error，节气用 tertiary，其余用次要色。
  static Color _markerColor(ColorScheme colorScheme, TodoDayExtra? extra) {
    if (extra == null) return colorScheme.onSurfaceVariant;
    final holiday = extra.holiday;
    if (holiday != null && (holiday.isHoliday || holiday.isWorkday)) {
      return colorScheme.error;
    }
    if (extra.solarTerm != null && extra.solarTerm!.isNotEmpty) {
      return colorScheme.tertiary;
    }
    return colorScheme.onSurfaceVariant;
  }
}

/// 月视图的 3×4 月份选择网格（1~12 月）。
class _MonthPickerGrid extends StatelessWidget {
  const _MonthPickerGrid({
    required this.focusedYear,
    required this.focusedMonth,
    required this.onMonthSelected,
  });

  final int focusedYear;
  final int focusedMonth;
  final ValueChanged<int> onMonthSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (rowIndex) {
        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex < 3 ? _gridRowGap : 0),
          child: Row(
            children: List.generate(3, (colIndex) {
              final month = rowIndex * 3 + colIndex + 1;
              return Expanded(
                child: _PickerCell(
                  label: '$month月',
                  height: _gridCellHeight,
                  isSelected: month == focusedMonth,
                  onTap: () => onMonthSelected(month),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

/// 年视图的 3×4 年份选择网格（当前十年窗口的 12 个年份）。
class _YearPickerGrid extends StatelessWidget {
  const _YearPickerGrid({
    required this.yearRangeStart,
    required this.yearRangeEnd,
    required this.focusedYear,
    required this.onYearSelected,
  });

  final int yearRangeStart;
  final int yearRangeEnd;
  final int focusedYear;
  final ValueChanged<int> onYearSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (rowIndex) {
        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex < 3 ? _gridRowGap : 0),
          child: Row(
            children: List.generate(3, (colIndex) {
              final year = yearRangeStart + rowIndex * 3 + colIndex;
              return Expanded(
                child: _PickerCell(
                  label: '$year年',
                  height: _gridCellHeight,
                  isSelected: year == focusedYear,
                  onTap: () => onYearSelected(year),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

/// 月/年选择网格的单个单元格（MD3 卡片风格）。
class _PickerCell extends StatelessWidget {
  const _PickerCell({
    required this.label,
    required this.height,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final double height;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        height: height,
        child: Material(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: textTheme.titleMedium?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
