import 'package:flutter/material.dart';

import 'package:ametoolbox/shared/widgets/adaptive_list_tile.dart';

import '../models/todo_item.dart';
import '../models/todo_priority.dart';
import 'todo_check_button.dart';

/// 优先级 → 颜色标识（spec §3.6）。
Color todoPriorityColor(TodoPriority priority, ColorScheme colorScheme) {
  return switch (priority) {
    TodoPriority.highest => colorScheme.error,
    TodoPriority.high => colorScheme.errorContainer,
    TodoPriority.medium => colorScheme.tertiary,
    TodoPriority.normal => colorScheme.onSurfaceVariant,
    TodoPriority.daily => colorScheme.secondary,
  };
}

/// 待办卡片。
///
/// 仅显示名称 + 辅助信息（优先级色点、分类色点、期限/循环标、过期标识）。
/// 前置完成勾选按钮（[showCheckButton] 为 false 时不显示），
/// 点击进详情，长按/右键可编辑或删除。
class TodoItemTile extends StatelessWidget {
  const TodoItemTile({
    super.key,
    required this.item,
    required this.isOverdue,
    required this.onTap,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    this.showCheckButton = true,
    this.categoryName,
    this.categoryColor,
  });

  final TodoItem item;
  final bool isOverdue;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// 是否显示前置完成勾选按钮（汇总页等场景可关闭）。
  final bool showCheckButton;

  /// 所属分类名称（未分类为 null）。
  final String? categoryName;

  /// 所属分类颜色（未分类为 null）。
  final Color? categoryColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final titleStyle = textTheme.titleMedium?.copyWith(
      color: item.isCompleted ? colorScheme.onSurfaceVariant : null,
      decoration: item.isCompleted ? TextDecoration.lineThrough : null,
    );

    return AdaptiveListTile(
      leading: showCheckButton
          ? TodoCheckButton(
              isCompleted: item.isCompleted,
              onChanged: onToggleComplete,
            )
          : null,
      title: Text(item.title, style: titleStyle),
      subtitle: _buildSubtitle(context, colorScheme),
      onTap: onTap,
      contextMenuBuilder: (context) => <PopupMenuEntry<void>>[
        PopupMenuItem<void>(
          onTap: onEdit,
          child: Text('编辑'),
        ),
        PopupMenuItem<void>(
          onTap: onDelete,
          child: Text('删除'),
        ),
      ],
    );
  }

  Widget _buildSubtitle(BuildContext context, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    final meta = <Widget>[
      // 优先级色点
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
        style: textTheme.bodySmall?.copyWith(
          color: todoPriorityColor(item.priority, colorScheme),
        ),
      ),
      if (categoryName != null && categoryColor != null) ...[
        const SizedBox(width: 8),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: categoryColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          categoryName!,
          style: textTheme.bodySmall?.copyWith(color: categoryColor),
        ),
      ],
      if (item.isRecurring) ...[
        const SizedBox(width: 8),
        Text(
          '循环',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.secondary,
          ),
        ),
      ],
      if (item.dueDate != null) ...[
        const SizedBox(width: 8),
        Text(
          _formatDate(item.dueDate!),
          style: textTheme.bodySmall?.copyWith(
            color: isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: meta,
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}