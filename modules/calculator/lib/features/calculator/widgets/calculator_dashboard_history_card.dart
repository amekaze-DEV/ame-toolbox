import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/calculation_history.dart';
import '../pages/calculator_page.dart';
import '../providers/calculator_config_provider.dart';
import '../services/history_backfill_service.dart';

/// 首页最近计算历史卡片。
///
/// 展示最近 5 条计算历史，点击条目时回填并进入模块主页。
class CalculatorDashboardHistoryCard extends ConsumerWidget {
  const CalculatorDashboardHistoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(calculatorConfigProvider).config.history;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openModule(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history_outlined,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '最近计算',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (history.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      '暂无计算记录',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length.clamp(0, 5),
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final record = history[index];
                      return _HistoryListTile(
                        record: record,
                        onTap: () => _backfillAndOpen(context, ref, record),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _backfillAndOpen(
    BuildContext context,
    WidgetRef ref,
    CalculationHistory record,
  ) async {
    await HistoryBackfillService.backfillExpression(ref, record);
    if (context.mounted) {
      _openModule(context);
    }
  }

  void _openModule(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CalculatorPage(),
      ),
    );
  }
}

class _HistoryListTile extends StatelessWidget {
  final CalculationHistory record;
  final VoidCallback onTap;

  const _HistoryListTile({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeText = DateFormat('MM-dd HH:mm').format(record.timestamp.toLocal());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.expression,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.result,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  timeText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
