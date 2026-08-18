import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/todo_config.dart';
import '../models/todo_item.dart';
import '../providers/todo_config_provider.dart';
import '../providers/todo_export_service_provider.dart';
import '../widgets/recurrence_rule_editor.dart' show describeRule;
import '../widgets/todo_image_attachments_editor.dart';
import '../widgets/todo_item_tile.dart' show todoPriorityColor;
import 'todo_detail_page.dart';

/// 待办查看子页面（只读）。
///
/// 仅展示待办内容（名称、详情、图片、优先级、期限、循环、提醒、完成状态），
/// 不支持直接编辑；右上角提供「编辑」按钮跳转到编辑页（可通过 [hideEdit] 隐藏）。
class TodoDetailViewPage extends ConsumerWidget {
  const TodoDetailViewPage({
    super.key,
    required this.item,
    this.hideEdit = false,
  });

  final TodoItem item;

  /// 是否隐藏编辑按钮（历史归档事项不需要编辑）。
  final bool hideEdit;

  void _openEdit(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TodoDetailPage(item: item),
      ),
    );
  }

  /// 导出当前这条待办为 Markdown（仅限本条内容）。
  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final markdown = ref.read(todoExportServiceProvider).toMarkdown([item]);
    await Clipboard.setData(ClipboardData(text: markdown));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制该待办 Markdown 到剪贴板')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final config = ref.watch(todoConfigProvider);
    final categoryName = _categoryName(config.config.categories, item.categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        actions: [
          AdaptiveIconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: '导出该待办为 Markdown',
            onPressed: () => _export(context, ref),
          ),
          if (!hideEdit)
            AdaptiveButton(
              variant: AdaptiveButtonVariant.text,
              icon: Icons.edit_outlined,
              label: '编辑',
              onPressed: () => _openEdit(context, ref),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 优先级
          _InfoRow(
            icon: Icons.flag_outlined,
            label: '优先级',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: todoPriorityColor(item.priority, colorScheme),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  item.priority.displayName,
                  style: textTheme.bodyLarge?.copyWith(
                    color: todoPriorityColor(item.priority, colorScheme),
                  ),
                ),
              ],
            ),
          ),
          if (categoryName != null)
            _InfoRow(
              icon: Icons.label_outline,
              label: '分类',
              child: Text(categoryName, style: textTheme.bodyLarge),
            ),
          if (item.isCompleted)
            _InfoRow(
              icon: Icons.check_circle_outline,
              label: '状态',
              child: Text(
                '已完成',
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.primary),
              ),
            ),
          // 详情
          const SizedBox(height: 8),
          Text('详情', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            (item.details?.isNotEmpty ?? false) ? item.details! : '暂无详情',
            style: (item.details?.isNotEmpty ?? false)
                ? textTheme.bodyMedium
                : textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
          ),
          const Divider(height: 32),
          // 图片附件（只读）
          TodoImageAttachmentsEditor(
            images: item.images,
            onChanged: (_) {},
            readOnly: true,
          ),
          const Divider(height: 32),
          // 期限 / 循环
          if (item.isRecurring) ...[
            Text('循环规则', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final rule in item.recurrenceRules)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.repeat),
                  title: Text(describeRule(rule)),
                  subtitle: Text(
                    '自 ${_fmt(rule.startDate)}'
                    '${rule.endDate == null ? ' · 无限循环' : ' 至 ${_fmt(rule.endDate!)}'}',
                  ),
                ),
              ),
          ] else if (item.dueDate != null)
            _InfoRow(
              icon: Icons.event_outlined,
              label: '期限',
              child: Text(_fmt(item.dueDate!), style: textTheme.bodyLarge),
            ),
          const Divider(height: 32),
          // 提醒
          _InfoRow(
            icon: Icons.notifications_outlined,
            label: '提醒',
            child: Text(
              _reminderSummary(item, config.config),
              style: textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  /// 提醒设置摘要。
  static String _reminderSummary(TodoItem item, TodoConfig config) {
    if (!item.remindEnabled) return '已关闭';
    final parts = <String>['执行 ${_fmtTime(item.executionTimeMinutes)}'];
    if (item.remindAtExecution) parts.add('执行时刻提醒');
    if (item.remindEarly) {
      final n = item.remindMinutes ?? config.defaultRemindMinutes;
      parts.add('提前$n分钟');
    }
    return parts.join('，');
  }

  static String _fmtTime(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  static String? _categoryName(List categories, String? categoryId) {
    if (categoryId == null) return null;
    for (final c in categories) {
      if (c.id == categoryId) return c.name;
    }
    return null;
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// 信息行（图标 + 标签 + 内容）。
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}