import 'package:flutter/material.dart';

import '../models/todo_priority.dart';
import 'todo_item_tile.dart' show todoPriorityColor;

/// 5 级优先级分段选择（spec §3.6）。
///
/// 使用 MD3 [SegmentedButton]，每段以优先级色点标识。
class TodoPrioritySelector extends StatelessWidget {
  const TodoPrioritySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TodoPriority value;
  final ValueChanged<TodoPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<TodoPriority>(
        showSelectedIcon: false,
        segments: [
          for (final p in TodoPriority.values)
            ButtonSegment<TodoPriority>(
              value: p,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: todoPriorityColor(p, colorScheme),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(p.displayName),
                ],
              ),
            ),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}