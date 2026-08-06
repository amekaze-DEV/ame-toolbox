import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/day_info.dart';
import '../models/shift_config.dart';
import '../providers/holiday_data_provider.dart';
import '../providers/lunar_info_provider.dart';
import '../providers/shift_calendar_provider.dart';
import '../providers/shift_config_provider.dart';
import '../providers/shift_schedule_provider.dart';
import '../utils/date_utils.dart';
import 'shift_assistant_settings_page.dart';

/// 日历视图。
///
/// 顶部单行工具栏集成年月导航、轮班选择、今日与设置；
/// 下方按周分组，每周块左侧为轮班状态行标签，右侧 7 列对应周一至周日，
/// 每个单元格显示日期及当天承担该状态的班组名称。窄宽度时每周块可横向滚动。
class MonthCalendarView extends ConsumerWidget {
  /// 单个日期单元格的最小宽度；7 列 + 标签列总宽低于此值时启用横向滚动。
  static const double _minDayCellWidth = 64;

  /// 左侧状态标签列宽度。
  static const double _shiftLabelWidth = 56;

  const MonthCalendarView({super.key});

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ShiftAssistantSettingsPage(),
      ),
    );
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
    final rotation = config.primaryRotation;

    final monthWeeks = calendarController.monthWeekGrid;
    final focusedMonth = calendarController.focusedMonth;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _CalendarToolbar(
            focusedMonth: focusedMonth,
            rotations: config.orderedRotations,
            primaryRotation: config.primaryRotation,
            onPreviousMonth: calendarController.previousMonth,
            onNextMonth: calendarController.nextMonth,
            onToday: calendarController.goToToday,
            onDateJump: (date) {
              calendarController.focusDate(date);
              calendarController.selectDate(date);
            },
            onRotationChanged: (rotationId) {
              if (rotationId != null) {
                configNotifier.setPrimaryRotation(rotationId);
              }
            },
            onSettings: () => _openSettings(context),
          ),
        ),
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
                    final holiday = holidayController.getHoliday(date);
                    return scheduleService.buildDayInfo(
                      rotation,
                      date,
                      lunarDate: lunarDate,
                      solarTerm: solarTerm,
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

/// 日历顶部工具栏：合并年月导航、轮班选择、日期转跳与设置入口。
class _CalendarToolbar extends StatelessWidget {
  const _CalendarToolbar({
    required this.focusedMonth,
    required this.rotations,
    required this.primaryRotation,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onRotationChanged,
    required this.onSettings,
    this.onDateJump,
  });

  final DateTime focusedMonth;
  final List<ShiftRotation> rotations;
  final ShiftRotation? primaryRotation;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final ValueChanged<String?> onRotationChanged;
  final VoidCallback onSettings;
  final ValueChanged<DateTime>? onDateJump;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final monthNav = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AdaptiveButton(
          onPressed: onPreviousMonth,
          label: '<',
          variant: AdaptiveButtonVariant.text,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        Text(
          formatMonthYear(focusedMonth),
          style: textTheme.titleMedium,
        ),
        AdaptiveButton(
          onPressed: onNextMonth,
          label: '>',
          variant: AdaptiveButtonVariant.text,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );

    final rotationDropdown = rotations.isEmpty
        ? const SizedBox.shrink()
        : DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: false,
              isDense: true,
              value: primaryRotation?.id,
              hint: const Text('选择轮班'),
              items: rotations.map((rotation) {
                return DropdownMenuItem(
                  value: rotation.id,
                  child: Text(
                    '${rotation.name}（轮班选择）',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onRotationChanged,
            ),
          );

    final toolbarRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        monthNav,
        const SizedBox(width: 12),
        if (rotations.isNotEmpty) rotationDropdown,
        const SizedBox(width: 24),
        if (onDateJump != null)
          AdaptiveButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: focusedMonth,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) onDateJump!(picked);
            },
            label: '日期转跳',
            variant: AdaptiveButtonVariant.text,
          ),
        AdaptiveButton(
          onPressed: onToday,
          label: '今日',
          variant: AdaptiveButtonVariant.text,
        ),
        AdaptiveIconButton(
          icon: Icon(Icons.settings, color: colorScheme.onSurfaceVariant),
          tooltip: '设置',
          onPressed: onSettings,
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: toolbarRow,
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
                  isSelected:
                      selectedDate != null && isSameDay(dayInfo.date, selectedDate!),
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
          const SizedBox(height: 24),
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
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(12),
          border: isToday
              ? Border.all(color: colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            // 日期行：公历日期 + 农历/节气/节假日标记
            Container(
              height: 24,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${dayInfo.date.day}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isCurrentMonth
                                ? (isToday ? colorScheme.primary : colorScheme.onSurface)
                                : colorScheme.outline,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                    ),
                    if (markerText != null)
                      Text(
                        markerText,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: markerColor,
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
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

  /// 获取日期单元格的附加标记文本：优先显示节假日/节气，其次农历日期。
  String? _dayMarkerText(DayInfo info) {
    if (info.solarTerm != null && info.solarTerm!.isNotEmpty) {
      return info.solarTerm;
    }
    if (info.holiday != null) {
      return info.holiday!.name;
    }
    if (info.lunarDate.isNotEmpty) {
      return info.lunarDate;
    }
    return null;
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
      () => ColorScheme.fromSeed(seedColor: Color(colorValue), brightness: brightness),
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
