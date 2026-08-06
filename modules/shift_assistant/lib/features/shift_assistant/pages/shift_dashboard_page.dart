import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/day_info.dart';
import '../models/shift_config.dart';
import '../providers/shift_dashboard_controller.dart';
import '../providers/shift_dashboard_provider.dart';
import '../utils/date_utils.dart';

/// 首页仪表盘页面。
///
/// 展示选中日期（默许今天）的公历/农历/节假日信息，以及当天所有班组的
/// 班次卡片；主要班组置顶并使用 `primaryContainer` 背景高亮。
class ShiftDashboardPage extends ConsumerWidget {
  const ShiftDashboardPage({super.key});

  static const List<String> _weekdays = [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(shiftDashboardProvider);
    final dashboardNotifier = ref.read(shiftDashboardProvider.notifier);
    final dayInfo = controller.dayInfo;
    final rotation = controller.configController.config.primaryRotation;
    final selectedDate = controller.selectedDate;
    final isToday = isSameDay(selectedDate, DateTime.now());
    final groups = rotation?.groups ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('仪表盘'),
        actions: [
          AdaptiveIconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: '选择日期',
            onPressed: () => _showDatePicker(context, dashboardNotifier),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _DateHeader(
                dayInfo: dayInfo,
                isToday: isToday,
                onGoToday: isToday ? null : dashboardNotifier.goToToday,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final group = groups[index];
                  final slot = dayInfo.shiftForGroup(group.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GroupShiftCard(
                      group: group,
                      slot: slot,
                      isPrimary: index == 0,
                    ),
                  );
                },
                childCount: groups.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Future<void> _showDatePicker(
    BuildContext context,
    ShiftDashboardController dashboardNotifier,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dashboardNotifier.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: '选择日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked == null) return;
    dashboardNotifier.selectDate(picked);
  }
}

/// 日期信息头图。
class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.dayInfo,
    required this.isToday,
    this.onGoToday,
  });

  final DayInfo dayInfo;
  final bool isToday;
  final VoidCallback? onGoToday;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final date = dayInfo.date;
    final holiday = dayInfo.holiday;

    final chips = <Widget>[];
    if (dayInfo.solarTerm != null && dayInfo.solarTerm!.isNotEmpty) {
      chips.add(_Chip(
        label: dayInfo.solarTerm!,
        color: colorScheme.tertiary,
      ));
    }
    if (holiday != null) {
      chips.add(_Chip(
        label: holiday.name,
        color: holiday.isWorkday ? colorScheme.error : colorScheme.error,
      ));
    }

    return Card(
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${date.month}月${date.day}日',
                  style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 12),
                Text(
                  ShiftDashboardPage._weekdays[date.weekday - 1],
                  style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
                if (!isToday) ...[
                  const Spacer(),
                  AdaptiveButton(
                    onPressed: onGoToday,
                    label: '返回今天',
                    variant: AdaptiveButtonVariant.text,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dayInfo.lunarDate.isEmpty ? '' : '农历 ${dayInfo.lunarDate}',
              style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: chips),
            ],
          ],
        ),
      ),
    );
  }
}

/// 信息标签。
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// 单个班组班次卡片。
class _GroupShiftCard extends StatelessWidget {
  const _GroupShiftCard({
    required this.group,
    required this.slot,
    required this.isPrimary,
  });

  final ShiftGroup group;
  final ShiftSlot? slot;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final groupScheme = ColorScheme.fromSeed(
      seedColor: Color(group.colorValue),
      brightness: Theme.of(context).brightness,
    );

    final background = isPrimary
        ? groupScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foreground = isPrimary
        ? groupScheme.onPrimaryContainer
        : colorScheme.onSurface;

    final shiftName = slot?.name ?? '未安排';
    final timeRange = _formatTime(slot);

    return Card(
      color: background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: Color(group.colorValue),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: textTheme.titleMedium?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        if (isPrimary)
                          Icon(
                            Icons.star,
                            size: 18,
                            color: groupScheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      shiftName,
                      style: textTheme.headlineSmall?.copyWith(
                            color: slot?.isRest ?? false
                                ? colorScheme.onSurfaceVariant
                                : foreground,
                          ),
                    ),
                    if (timeRange != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        timeRange,
                        style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _formatTime(ShiftSlot? slot) {
    if (slot == null || slot.isRest) return null;
    if (slot.startTime == null || slot.endTime == null) return null;
    return '${slot.startTime} - ${slot.endTime}';
  }
}
