import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/shared/utils/app_text_styles.dart';

import '../models/shift_config.dart';
import '../providers/holiday_data_controller.dart';
import '../providers/holiday_data_provider.dart';
import '../providers/lunar_info_provider.dart';
import '../providers/shift_config_provider.dart';
import '../providers/shift_schedule_provider.dart';
import '../services/lunar_info_service.dart';
import '../services/shift_schedule_service.dart';

/// 倒班助手首页快速卡片。
///
/// 展示今日公历 / 农历 / 节气 / 节假日与调休信息，并在用户设置「我的班组」
/// 时突出显示该班组今日班次；同时展示当前轮班（倒班助手页显示的轮班）今日
/// 各班组班次。卡片高度随内容自适应，颜色全部取自 [ColorScheme]。
class ShiftAssistantDashboardQuickCard extends ConsumerWidget {
  const ShiftAssistantDashboardQuickCard({
    super.key,
    required this.onOpenModule,
  });

  /// 进入倒班助手模块主页的回调（切换底座导航，保留导航栏）。
  final VoidCallback onOpenModule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(shiftConfigProvider).config;
    final lunarService = ref.watch(lunarInfoServiceProvider);
    final holidayController = ref.watch(holidayDataProvider);
    final scheduleService = ref.watch(shiftScheduleProvider);

    final now = DateTime.now();
    final rotation = config.selectedRotation;

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenModule,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month_outlined,
                      color: colorScheme.primary, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '倒班助手',
                      style: AppTextStyles.cardTitle(context),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 今日日期区与我的班组区并排显示，充分利用卡片宽度。
              if (config.myTeamGroup != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDateSection(
                        context,
                        now: now,
                        lunarService: lunarService,
                        holidayController: holidayController,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMyTeamSection(
                        context,
                        config: config,
                        scheduleService: scheduleService,
                        now: now,
                      ),
                    ),
                  ],
                )
              else
                _buildDateSection(
                  context,
                  now: now,
                  lunarService: lunarService,
                  holidayController: holidayController,
                ),
              const SizedBox(height: 10),
              _buildRotationSection(
                context,
                scheduleService: scheduleService,
                rotation: rotation,
                now: now,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 今日日期区块：公历 + 农历/节气/节日 + 休班标记。
  Widget _buildDateSection(
    BuildContext context, {
    required DateTime now,
    required LunarInfoService lunarService,
    required HolidayDataController holidayController,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final lunarDate = lunarService.getLunarDate(now);
    final solarTerm = lunarService.getSolarTerm(now);
    final solarFestivals = lunarService.getSolarFestivals(now);
    final holiday = holidayController.getHoliday(now);

    // 附加标记：公历节日优先，其次节气（农历日期已移至「今日」标题右侧）。
    final markers = <String>[
      ...solarFestivals,
      if (solarTerm != null && solarTerm.isNotEmpty) solarTerm,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行：「今日」与农历日期相邻展示。
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('今日', style: AppTextStyles.sectionTitle(context)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '农历$lunarDate',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              // 自适应缩放：与我的班组并排后空间较窄，超出时等比缩小。
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatSolarDate(now),
                  style: textTheme.headlineSmall,
                ),
              ),
            ),
            if (holiday != null) ...[
              const SizedBox(width: 8),
              _HolidayBadge(holiday: holiday),
            ],
          ],
        ),
        if (markers.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            markers.join(' · '),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// 我的班组区块：仅当用户设置了「我的班组」时显示。
  Widget _buildMyTeamSection(
    BuildContext context, {
    required ShiftConfig config,
    required ShiftScheduleService scheduleService,
    required DateTime now,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final team = config.myTeamGroup;
    if (team == null) return const SizedBox.shrink();

    final rotation = config.findRotationById(config.myTeamRotationId!);
    final slot = rotation == null
        ? null
        : scheduleService.calculateShiftsForDate(rotation, now)[team.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('我的班组', style: AppTextStyles.sectionTitle(context)),
        const SizedBox(height: 4),
        Row(
          children: [
            _GroupChip(
              label: team.name,
              colorValue: team.colorValue,
              highlight: true,
            ),
            const SizedBox(width: 8),
            Expanded(
              // 班次文字较长时等比缩小，避免与左侧班组色块挤压溢出。
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  slot == null ? '暂无班次数据' : _formatSlot(slot),
                  style: textTheme.bodyMedium,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 当前轮班今日区块：展示当前轮班各班组今日班次。
  Widget _buildRotationSection(
    BuildContext context, {
    required ShiftScheduleService scheduleService,
    required ShiftRotation? rotation,
    required DateTime now,
  }) {
    final textTheme = Theme.of(context).textTheme;

    if (rotation == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('当前轮班', style: AppTextStyles.sectionTitle(context)),
          const SizedBox(height: 4),
          Text(
            '暂无轮班，请到设置页添加',
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final shifts = scheduleService.calculateShiftsForDate(rotation, now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '当前轮班 · ${rotation.name}',
          style: AppTextStyles.sectionTitle(context),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: rotation.groups.map((group) {
            final slot = shifts[group.id];
            return _GroupChip(
              label: slot == null
                  ? '${group.name}：-'
                  : '${group.name} · ${_formatSlot(slot)}',
              colorValue: group.colorValue,
              highlight: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 公历日期展示：如“8月9日 星期日”。
  String _formatSolarDate(DateTime date) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '${date.month}月${date.day}日 星期${weekdays[date.weekday - 1]}';
  }

  /// 班次展示：状态名 + 起止时间（休息状态无时间）。
  String _formatSlot(ShiftSlot slot) {
    if (slot.startTime == null || slot.endTime == null) return slot.name;
    return '${slot.name} ${slot.startTime}-${slot.endTime}';
  }
}

/// 休/班 标记徽章。
class _HolidayBadge extends StatelessWidget {
  const _HolidayBadge({required this.holiday});

  final HolidayInfo holiday;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWorkday = holiday.isWorkday;
    final color = colorScheme.error;
    final label = isWorkday ? '班' : '休';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label${holiday.name}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
            ),
      ),
    );
  }
}

/// 班组班次标签，按班组颜色生成 MD3 色板。
class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.label,
    required this.colorValue,
    this.highlight = false,
  });

  final String label;
  final int colorValue;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = ColorScheme.fromSeed(
      seedColor: Color(colorValue),
      brightness: brightness,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight ? scheme.primary : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: highlight ? scheme.onPrimary : scheme.onPrimaryContainer,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
