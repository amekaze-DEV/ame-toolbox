import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/day_info.dart';
import '../models/shift_config.dart';
import '../providers/holiday_data_provider.dart';
import '../providers/lunar_info_provider.dart';
import '../providers/shift_calendar_controller.dart';
import '../providers/shift_calendar_provider.dart';
import '../providers/shift_config_provider.dart';
import '../providers/shift_schedule_provider.dart';
import '../utils/date_utils.dart';
import 'shift_assistant_settings_page.dart';

/// 日历视图。
///
/// 顶部工具栏集年月导航、轮班选择、今日与设置于一体。
/// 支持三级视图切换：日视图（默认）→ 点击标题 → 月视图 → 点击标题 → 年视图。
/// 日视图下方按周分组，每周块左侧为轮班状态行标签，右侧 7 列对应周一至周日。
/// 月/年视图分别显示 3×4 的月份/年份选择网格。
class MonthCalendarView extends ConsumerWidget {
  /// 单个日期单元格的最小宽度；7 列 + 标签列总宽低于此值时启用横向滚动。
  static const double _minDayCellWidth = 42;

  /// 左侧状态标签列宽度。
  static const double _shiftLabelWidth = 48;

  const MonthCalendarView({super.key});

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ShiftAssistantSettingsPage(),
      ),
    );
  }

  /// 根据当前视图层级计算标题文本。
  String _titleForLevel(ShiftCalendarController controller) {
    switch (controller.viewLevel) {
      case CalendarViewLevel.day:
        return formatMonthYear(controller.focusedMonth);
      case CalendarViewLevel.month:
        return formatYear(controller.focusedDate.year);
      case CalendarViewLevel.year:
        return formatYearRange(controller.yearRangeStart, controller.yearRangeEnd);
    }
  }

  /// 标题点击：日→月，月→年，年无操作。
  void _onTitleTap(ShiftCalendarController controller) {
    switch (controller.viewLevel) {
      case CalendarViewLevel.day:
        controller.showMonthPicker();
        break;
      case CalendarViewLevel.month:
        controller.showYearPicker();
        break;
      case CalendarViewLevel.year:
        // 最深层级，不操作。
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configController = ref.watch(shiftConfigProvider);
    final configNotifier = ref.read(shiftConfigProvider.notifier);
    final calendarController = ref.watch(shiftCalendarProvider);
    final scheduleService = ref.watch(shiftScheduleProvider);
    final lunarService = ref.watch(lunarInfoServiceProvider);
    final holidayController = ref.watch(holidayDataProvider);
    final config = configController.config;
    final rotation = config.selectedRotation;

    final monthWeeks = calendarController.monthWeekGrid;
    final focusedMonth = calendarController.focusedMonth;

    final toolbar = _CalendarToolbar(
      titleText: _titleForLevel(calendarController),
      onTitleTap: () => _onTitleTap(calendarController),
      onPreviousUnit: calendarController.previousUnit,
      onNextUnit: calendarController.nextUnit,
      rotations: config.rotations,
      selectedRotation: config.selectedRotation,
      onToday: calendarController.goToToday,
      onDateJump: (date) => calendarController.jumpToDate(date),
      onRotationChanged: (rotationId) {
        if (rotationId != null) {
          configNotifier.setLastViewedRotation(rotationId);
        }
      },
      onSettings: () => _openSettings(context),
    );

    if (calendarController.viewLevel != CalendarViewLevel.day) {
      // 月/年视图：固定工具栏 + 自适应网格。
      // 不使用 SliverFillRemaining：它以视口宽度做 child intrinsic 测量，
      // 网格中 AspectRatio/单元格会据此被撑高，产生滚动条与向下位移；
      // Column + Expanded 让网格在真实可用空间内由 FittedBox 等比缩放。
      return Column(
        children: [
          toolbar,
          Expanded(
            child: calendarController.viewLevel == CalendarViewLevel.month
                ? _MonthPickerGrid(
                    focusedYear: calendarController.focusedDate.year,
                    focusedMonth: calendarController.focusedDate.month,
                    onMonthSelected: (month) =>
                        calendarController.selectMonth(month),
                  )
                : _YearPickerGrid(
                    yearRangeStart: calendarController.yearRangeStart,
                    yearRangeEnd: calendarController.yearRangeEnd,
                    focusedYear: calendarController.focusedDate.year,
                    onYearSelected: (year) =>
                        calendarController.selectYear(year),
                  ),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: toolbar),
        SliverToBoxAdapter(
          child: _WeekdayHeader(
            shiftLabelWidth: _shiftLabelWidth,
            minDayCellWidth: _minDayCellWidth,
          ),
        ),
        if (rotation == null)
          const SliverFillRemaining(
            child: Center(child: Text('暂无轮班，请先到设置页添加')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final week = monthWeeks[index];
                  final slotNames = scheduleService.slotNames(rotation);
                  final weekDayInfo = week.map((date) {
                    final lunarDate = lunarService.getLunarDate(date);
                    final solarTerm = lunarService.getSolarTerm(date);
                    final solarFestivals =
                        lunarService.getSolarFestivals(date);
                    final holiday = holidayController.getHoliday(date);
                    return scheduleService.buildDayInfo(
                      rotation,
                      date,
                      lunarDate: lunarDate,
                      solarTerm: solarTerm,
                      solarFestivals: solarFestivals,
                      holiday: holiday,
                    );
                  }).toList();
                  return _WeekBlock(
                    weekDayInfo: weekDayInfo,
                    rotation: rotation,
                    slotNames: slotNames,
                    focusedMonth: focusedMonth,
                    selectedDate: calendarController.selectedDate,
                    onDateSelected: calendarController.selectDate,
                    shiftLabelWidth: _shiftLabelWidth,
                    minDayCellWidth: _minDayCellWidth,
                  );
                },
                childCount: monthWeeks.length,
              ),
            ),
          ),
      ],
    );
  }
}

/// 工具栏标题（年月/年/年份范围）的固定宽度。
///
/// 标题文字在该宽度内居中显示，超出部分等比缩小；
/// 宽度固定使前后切换箭头位置固定，不随标题文字长度变化而移动。
const double _titleFixedWidth = 112;

/// 日历顶部工具栏。
///
/// 显示可点击的年月/年/年份范围标题 + 前后箭头 + 轮班选择 + 日期转跳 + 今日 + 设置。
/// 宽度充足时单行展示，右侧控件贴近窗口右边框；
/// 宽度不足时自动折为两行：第一行（标题+箭头 + 轮班选择 + 设置），
/// 第二行（日期转跳 + 今日），纵向保持紧凑。
class _CalendarToolbar extends StatefulWidget {
  const _CalendarToolbar({
    required this.titleText,
    required this.onTitleTap,
    required this.onPreviousUnit,
    required this.onNextUnit,
    required this.rotations,
    required this.selectedRotation,
    required this.onToday,
    required this.onRotationChanged,
    required this.onSettings,
    this.onDateJump,
  });

  final String titleText;
  final VoidCallback onTitleTap;
  final VoidCallback onPreviousUnit;
  final VoidCallback onNextUnit;
  final List<ShiftRotation> rotations;
  final ShiftRotation? selectedRotation;
  final VoidCallback onToday;
  final ValueChanged<String?> onRotationChanged;
  final VoidCallback onSettings;
  final ValueChanged<DateTime>? onDateJump;

  @override
  State<_CalendarToolbar> createState() => _CalendarToolbarState();
}

class _CalendarToolbarState extends State<_CalendarToolbar> {
  /// 隐藏测量副本中单行工具栏的总宽度；null 表示尚未测量。
  double? _singleRowWidth;

  final GlobalKey _measureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant _CalendarToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 轮班名称变化会影响下拉框宽度，需重新测量。
    if (oldWidget.rotations != widget.rotations ||
        oldWidget.selectedRotation?.id != widget.selectedRotation?.id ||
        oldWidget.titleText != widget.titleText) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  /// 测量单行工具栏内容宽度（通过隐藏的横向滚动副本获得无界宽度）。
  void _measure() {
    final context = _measureKey.currentContext;
    if (context == null || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox) return;
    final width = box.size.width;
    if (_singleRowWidth != width) {
      setState(() => _singleRowWidth = width);
    }
  }

  /// 标题显示区：固定宽度容器，文字始终居中。
  ///
  /// 宽度固定保证前后切换箭头位置不随标题长度变化而移动
  /// （如“2026年8月”→“2026年12月”）；文字超出时等比缩小避免溢出。
  Widget _buildTitleArea() {
    return SizedBox(
      width: _titleFixedWidth,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.titleText,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 通用标题导航行：箭头 + 可点击标题 + 箭头。
    final titleNav = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AdaptiveButton(
          onPressed: widget.onPreviousUnit,
          variant: AdaptiveButtonVariant.text,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Icon(Icons.chevron_left, size: 20),
        ),
        GestureDetector(
          onTap: widget.onTitleTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: _buildTitleArea(),
          ),
        ),
        AdaptiveButton(
          onPressed: widget.onNextUnit,
          variant: AdaptiveButtonVariant.text,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Icon(Icons.chevron_right, size: 20),
        ),
      ],
    );

    // 测量副本专用标题行：不含手势处理器，避免语义树冲突。
    final measureTitleNav = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AdaptiveButton(
          onPressed: widget.onPreviousUnit,
          variant: AdaptiveButtonVariant.text,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Icon(Icons.chevron_left, size: 20),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: _buildTitleArea(),
        ),
        AdaptiveButton(
          onPressed: widget.onNextUnit,
          variant: AdaptiveButtonVariant.text,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Icon(Icons.chevron_right, size: 20),
        ),
      ],
    );

    // MD3 描边框体：提醒用户轮班可在此切换。
    // isExpanded:false 时按钮按内容固有宽度渲染（用于测量与单行布局）；
    // isExpanded:true 时填充可用宽度，选中项文字可省略（用于双行布局受限空间）。
    Widget buildDropdown({required bool isExpanded}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: isExpanded,
              isDense: true,
              value: widget.selectedRotation?.id,
              hint: const Text('选择轮班'),
              items: widget.rotations.map((rotation) {
                return DropdownMenuItem(
                  value: rotation.id,
                  child: Text(
                    rotation.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              // 选中项限制最大宽度：超长轮班名称省略显示，避免把框体撑出边界。
              selectedItemBuilder: (context) => widget.rotations
                  .map(
                    (rotation) => ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        rotation.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: widget.onRotationChanged,
            ),
          ),
        );

    // 测量与单行布局使用的版本：按内容固有宽度显示。
    final rotationDropdown = widget.rotations.isEmpty
        ? const SizedBox.shrink()
        : buildDropdown(isExpanded: false);

    // 双行布局显示版本：填充可用宽度但不超过固有宽度上限（内容宽 + 内边距），
    // 空间不足时选中项文字省略，避免溢出。
    final displayRotationDropdown = widget.rotations.isEmpty
        ? const SizedBox.shrink()
        : ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 224),
            child: buildDropdown(isExpanded: true),
          );

    final dateJumpButton = widget.onDateJump == null
        ? null
        : AdaptiveButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) widget.onDateJump!(picked);
            },
            label: '日期转跳',
            variant: AdaptiveButtonVariant.text,
          );

    final todayButton = AdaptiveButton(
      onPressed: widget.onToday,
      label: '今日',
      variant: AdaptiveButtonVariant.text,
    );

    final settingsButton = AdaptiveIconButton(
      icon: Icon(Icons.settings, color: colorScheme.onSurfaceVariant),
      tooltip: '设置',
      onPressed: widget.onSettings,
    );

    // 隐藏测量副本：横向滚动视图提供无界宽度，Row 取内容固有宽度。
    // 测量副本使用 measureTitleNav（不含手势处理器），避免语义树冲突。
    final measureRow = Row(
      key: _measureKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        measureTitleNav,
        const SizedBox(width: 12),
        if (widget.rotations.isNotEmpty) rotationDropdown,
        const SizedBox(width: 24),
        ?dateJumpButton,
        todayButton,
        settingsButton,
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 尚未测量时按双行渲染，避免首帧溢出；测量完成后按宽度自适应。
          final width = _singleRowWidth;
          final twoRows = width == null || width > constraints.maxWidth;

          return Stack(
            children: [
              // 隐藏副本仅用于测量，不参与绘制。
              Offstage(
                offstage: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: measureRow,
                ),
              ),
              if (twoRows)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 第一行：标题+箭头 + 轮班选择 + 设置（设置贴近右边缘）。
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              titleNav,
                              const SizedBox(width: 12),
                              if (widget.rotations.isNotEmpty)
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: displayRotationDropdown,
                                ),
                            ],
                          ),
                        ),
                        settingsButton,
                      ],
                    ),
                    const SizedBox(height: 2),
                    // 第二行：日期转跳 + 今日，贴近右边缘。
                    Row(
                      children: [
                        const Spacer(),
                        ?dateJumpButton,
                        todayButton,
                      ],
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    titleNav,
                    const SizedBox(width: 12),
                    if (widget.rotations.isNotEmpty) rotationDropdown,
                    const Spacer(),
                    ?dateJumpButton,
                    todayButton,
                    settingsButton,
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
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

/// 基准布局下单元格的宽高比。
const double _gridCellAspectRatio = 1.5;

/// 基准布局下单元格宽度。
final double _gridCellWidth = (_gridBaseWidth - 2 * _gridHorizontalPadding) / 3;

/// 基准布局下单元格高度。
final double _gridCellHeight = _gridCellWidth / _gridCellAspectRatio;

/// 网格内容高度（4 行 + 3 行间距，不含内外边距）。
///
/// 单元格使用固定高度而非 [AspectRatio]：AspectRatio 的 intrinsic 高度
/// 由传入宽度推导，而 [SliverFillRemaining] 以视口宽度做 intrinsic 测量，
/// 会在宽窗口下把网格撑高并产生滚动条。固定高度使 intrinsic 恒定。
final double _gridContentHeight = 4 * _gridCellHeight + 3 * _gridRowGap;

/// 3×4 月份选择网格。
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
    return Center(
      // 固定基准尺寸，超出可用空间时整体等比缩放，保证任意长宽比下完整显示。
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _gridHorizontalPadding,
            vertical: _gridVerticalPadding,
          ),
          child: SizedBox(
            width: _gridBaseWidth,
            height: _gridContentHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (rowIndex) {
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: rowIndex < 3 ? _gridRowGap : 0),
                  child: Row(
                    children: List.generate(3, (colIndex) {
                      final month = rowIndex * 3 + colIndex + 1;
                      return Expanded(
                        child: _PickerCell(
                          label: '$month月',
                          isSelected: month == focusedMonth,
                          height: _gridCellHeight,
                          onTap: () => onMonthSelected(month),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// 3×4 年份选择网格（12 年窗口）。
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
    return Center(
      // 固定基准尺寸，超出可用空间时整体等比缩放，保证任意长宽比下完整显示。
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _gridHorizontalPadding,
            vertical: _gridVerticalPadding,
          ),
          child: SizedBox(
            width: _gridBaseWidth,
            height: _gridContentHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (rowIndex) {
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: rowIndex < 3 ? _gridRowGap : 0),
                  child: Row(
                    children: List.generate(3, (colIndex) {
                      final year = yearRangeStart + rowIndex * 3 + colIndex;
                      return Expanded(
                        child: _PickerCell(
                          label: '$year年',
                          isSelected: year == focusedYear,
                          height: _gridCellHeight,
                          onTap: () => onYearSelected(year),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// 单个月份/年份选择格，MD3 样式。
class _PickerCell extends StatelessWidget {
  const _PickerCell({
    required this.label,
    required this.isSelected,
    required this.height,
    required this.onTap,
  });

  final String label;
  final bool isSelected;

  /// 固定高度；使用固定高度而非 [AspectRatio]，保证网格 intrinsic 高度
  /// 与视口宽度无关（避免宽窗口下 SliverFillRemaining 撑出滚动条）。
  final double height;
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
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
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

/// 星期标题行（一 ~ 日）。
class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({
    required this.shiftLabelWidth,
    required this.minDayCellWidth,
  });

  final double shiftLabelWidth;
  final double minDayCellWidth;

  @override
  Widget build(BuildContext context) {
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final requiredWidth = shiftLabelWidth + minDayCellWidth * 7;
          final availableWidth = constraints.maxWidth;
          final fits = availableWidth >= requiredWidth;
          final cellWidth = fits
              ? (availableWidth - shiftLabelWidth) / 7
              : minDayCellWidth;

          final content = Row(
            children: [
              SizedBox(width: shiftLabelWidth),
              ...weekdays.map(
                (day) => SizedBox(
                  width: cellWidth,
                  child: Text(
                    day,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );

          return fits
              ? content
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: content,
                );
        },
      ),
    );
  }
}

/// 单周块：包含左侧状态标签与 7×N 的日期网格。
class _WeekBlock extends StatelessWidget {
  const _WeekBlock({
    required this.weekDayInfo,
    required this.rotation,
    required this.slotNames,
    required this.focusedMonth,
    required this.selectedDate,
    required this.onDateSelected,
    required this.shiftLabelWidth,
    required this.minDayCellWidth,
  });

  final List<DayInfo> weekDayInfo;
  final ShiftRotation rotation;
  final List<String> slotNames;
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final double shiftLabelWidth;
  final double minDayCellWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final requiredWidth = shiftLabelWidth + minDayCellWidth * 7;
        final availableWidth = constraints.maxWidth;
        final fits = availableWidth >= requiredWidth;
        final cellWidth = fits
            ? (availableWidth - shiftLabelWidth) / 7
            : minDayCellWidth;

        // 仅保留本周内实际出现班组的状态，去除空行。
        final activeSlotNames = <String>{};
        for (final dayInfo in weekDayInfo) {
          for (final group in rotation.groups) {
            final slot = dayInfo.shiftForGroup(group.id);
            if (slot != null) {
              activeSlotNames.add(slot.name);
            }
          }
        }
        final orderedActiveSlots =
            slotNames.where((s) => activeSlotNames.contains(s)).toList();

        final content = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShiftLabelColumn(
              slotNames: orderedActiveSlots,
              width: shiftLabelWidth,
            ),
            ...List.generate(7, (dayIndex) {
              final dayInfo = weekDayInfo[dayIndex];
              return SizedBox(
                width: cellWidth,
                child: _DayColumn(
                  dayInfo: dayInfo,
                  rotation: rotation,
                  slotNames: orderedActiveSlots,
                  focusedMonth: focusedMonth,
                  isSelected: selectedDate != null &&
                      isSameDay(dayInfo.date, selectedDate!),
                  onTap: () => onDateSelected(dayInfo.date),
                ),
              );
            }),
          ],
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: fits
              ? content
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: content,
                ),
        );
      },
    );
  }
}

/// 左侧状态标签列。
class _ShiftLabelColumn extends StatelessWidget {
  const _ShiftLabelColumn({
    required this.slotNames,
    required this.width,
  });

  final List<String> slotNames;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: Column(
        children: [
          // 与 _DayColumn 顶部的日期行对齐。
          const SizedBox(height: 44),
          ...slotNames.map((name) {
            return Container(
              height: 24,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: Text(
                name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 单日列：顶部日期，下方按状态行显示承担该状态的班组。
class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.dayInfo,
    required this.rotation,
    required this.slotNames,
    required this.focusedMonth,
    required this.isSelected,
    required this.onTap,
  });

  final DayInfo dayInfo;
  final ShiftRotation rotation;
  final List<String> slotNames;
  final DateTime focusedMonth;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isToday = isSameDay(dayInfo.date, DateTime.now());
    final isCurrentMonth = dayInfo.date.month == focusedMonth.month;

    final markerText = _dayMarkerText(dayInfo);
    final markerColor = _dayMarkerColor(context, dayInfo);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(12),
        ),
        // 边框置于前景装饰层，绘制在班组卡片之上，避免被遮挡。
        foregroundDecoration: isToday
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary, width: 1.5),
              )
            : null,
        child: Column(
          children: [
            // 日期行：公历日期 + 农历/节气/节假日标记
            Container(
              height: 44,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _dayLabel(dayInfo),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontSize: 14,
                          height: 1.0,
                          color: _dayLabelColor(
                            dayInfo,
                            markerColor,
                            isCurrentMonth,
                            isToday,
                            colorScheme,
                          ),
                          // 三档日期统一加粗：非当月浅灰、当月常规色、当日主题色 + 描边。
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (markerText != null)
                    // 自适应字体：节日名称长短不一，超出单元格宽度时等比缩小。
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          markerText,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                height: 1.0,
                                color: markerColor,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 各状态行：显示当天处于该状态的班组
            ...slotNames.map((slotName) {
              final groups = _groupsForSlot(slotName);
              return Container(
                height: 24,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                child: _GroupLabel(
                  groups: groups,
                  color: isCurrentMonth
                      ? colorScheme.onSurface
                      : colorScheme.outline,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<ShiftGroup> _groupsForSlot(String slotName) {
    final result = <ShiftGroup>[];
    for (final group in rotation.groups) {
      final slot = dayInfo.shiftForGroup(group.id);
      if (slot != null && slot.name == slotName) {
        result.add(group);
      }
    }
    return result;
  }

  /// 获取日期单元格的附加标记文本：公历节日（国庆、教师、母亲等）优先，
  /// 其次节气，再次农历日期。节假日/调休信息已由公历日期旁的"休/班"标记表达。
  String? _dayMarkerText(DayInfo info) {
    if (info.solarFestivals.isNotEmpty) {
      return info.solarFestivals.first;
    }
    if (info.solarTerm != null && info.solarTerm!.isNotEmpty) {
      return info.solarTerm;
    }
    if (info.lunarDate.isNotEmpty) {
      return info.lunarDate;
    }
    return null;
  }

  /// 生成日期格子左上用于公历日期的文本：法定假日尾缀"休"，调休工作日尾缀"班"。
  String _dayLabel(DayInfo info) {
    final holiday = info.holiday;
    if (holiday != null && holiday.isHoliday) return '${info.date.day}休';
    if (holiday != null && holiday.isWorkday) return '${info.date.day}班';
    return '${info.date.day}';
  }

  /// 公历日期文字颜色：休/班用节假日标记色突出，其余按月份/今日区分。
  Color _dayLabelColor(
    DayInfo info,
    Color markerColor,
    bool isCurrentMonth,
    bool isToday,
    ColorScheme colorScheme,
  ) {
    final holiday = info.holiday;
    if (holiday != null && (holiday.isHoliday || holiday.isWorkday)) {
      return markerColor;
    }
    if (!isCurrentMonth) return colorScheme.outline;
    return isToday ? colorScheme.primary : colorScheme.onSurface;
  }

  /// 获取日期单元格附加标记的颜色。
  Color _dayMarkerColor(BuildContext context, DayInfo info) {
    final colorScheme = Theme.of(context).colorScheme;
    final holiday = info.holiday;
    if (holiday != null && holiday.isWorkday) {
      return colorScheme.error;
    }
    if (holiday != null && holiday.isHoliday) {
      return colorScheme.error;
    }
    if (info.solarTerm != null && info.solarTerm!.isNotEmpty) {
      return colorScheme.tertiary;
    }
    return colorScheme.onSurfaceVariant;
  }
}

/// 为班组颜色生成 MD3 [ColorScheme] 的缓存助手。
class _GroupColorSchemeCache {
  static final _cache = <int, ColorScheme>{};

  static ColorScheme schemeFor(BuildContext context, int colorValue) {
    final brightness = Theme.of(context).brightness;
    final key = colorValue ^ (brightness == Brightness.dark ? 1 : 0);
    return _cache.putIfAbsent(
      key,
      () => ColorScheme.fromSeed(
          seedColor: Color(colorValue), brightness: brightness),
    );
  }
}

/// 班组名称标签，自动缩放以适应窄单元格。
class _GroupLabel extends StatelessWidget {
  const _GroupLabel({
    required this.groups,
    required this.color,
  });

  final List<ShiftGroup> groups;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    final text = groups.map((g) => g.name).join(',');
    final primary = groups.first;

    final background = _GroupColorSchemeCache.schemeFor(context, primary.colorValue)
        .primaryContainer;
    final foreground = _GroupColorSchemeCache.schemeFor(context, primary.colorValue)
        .onPrimaryContainer;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
              ),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }
}