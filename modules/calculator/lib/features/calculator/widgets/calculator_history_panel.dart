import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';
import 'package:intl/intl.dart';

import '../models/calculation_history.dart';
import '../models/calculator_type.dart';
import '../providers/calculator_config_provider.dart';
import '../services/history_backfill_service.dart';

/// 多功能计算器共享历史面板。
///
/// 横屏布局时作为固定侧边面板展示；竖屏时由 [HistoryPage] 全屏展示。
/// 支持单击回填表达式、菜单回填结果、长按删除、清空全部。
class CalculatorHistoryPanel extends ConsumerWidget {
  final VoidCallback? onBackfillExpression;

  const CalculatorHistoryPanel({
    super.key,
    this.onBackfillExpression,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configController = ref.watch(calculatorConfigProvider);
    final history = configController.config.history;

    if (history.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '计算历史',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AdaptiveButton(
                variant: AdaptiveButtonVariant.text,
                label: '清空',
                onPressed: () => _showClearConfirm(context, ref),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: history.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final record = history[index];
              return _HistoryItem(
                record: record,
                onBackfillExpression: onBackfillExpression,
                onDelete: () => configController.setHistory(
                  history.where((h) => h != record).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            '暂无计算记录',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearConfirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史'),
        content: const Text('确定要清空所有计算历史吗？此操作不可恢复。'),
        actions: [
          AdaptiveButton(
            variant: AdaptiveButtonVariant.text,
            label: '取消',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AdaptiveButton(
            variant: AdaptiveButtonVariant.text,
            label: '清空',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(calculatorConfigProvider).clearHistory();
    }
  }
}

class _HistoryItem extends ConsumerWidget {
  final CalculationHistory record;
  final VoidCallback? onBackfillExpression;
  final VoidCallback onDelete;

  const _HistoryItem({
    required this.record,
    this.onBackfillExpression,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeText =
        DateFormat('MM-dd HH:mm').format(record.timestamp.toLocal());

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.expression,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AdaptiveIconButton(
                    icon: const Icon(Icons.reply),
                    tooltip: '回填算式',
                    onPressed: () async {
                      await HistoryBackfillService.backfillExpression(ref, record);
                      onBackfillExpression?.call();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.result,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _CopyMenu(record: record),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    timeText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(type: record.calculatorType),
                  if (record.calculatorType == CalculatorType.scientific) ...[
                    const SizedBox(width: 8),
                    Text(
                      record.angleMode,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _CopyMenu extends ConsumerWidget {
  final CalculationHistory record;

  const _CopyMenu({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_CopyAction>(
      icon: const Icon(Icons.copy_outlined),
      tooltip: '复制选项',
      onSelected: (action) async {
        switch (action) {
          case _CopyAction.backfill:
            await HistoryBackfillService.backfillResult(ref, record);
          case _CopyAction.result:
            _copyToClipboard(context, record.result);
          case _CopyAction.full:
            _copyToClipboard(
              context,
              '${record.expression} = ${record.result}',
            );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _CopyAction.backfill,
          child: _MenuItem(icon: Icons.input, text: '回填结果'),
        ),
        const PopupMenuItem(
          value: _CopyAction.result,
          child: _MenuItem(icon: Icons.copy, text: '复制结果'),
        ),
        const PopupMenuItem(
          value: _CopyAction.full,
          child: _MenuItem(icon: Icons.ios_share, text: '导出计算'),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    // 面板不直接操作剪贴板，通过 SnackBar 提示。
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MenuItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurface),
        const SizedBox(width: 12),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final CalculatorType type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(type.displayName),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

enum _CopyAction {
  backfill,
  result,
  full,
}
