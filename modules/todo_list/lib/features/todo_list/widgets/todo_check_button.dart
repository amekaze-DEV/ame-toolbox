import 'package:flutter/material.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

/// 待办完成勾选按钮。
///
/// 使用底座 [AdaptiveIconButton] 保证触控模式 48×48 dp 点击区域。
class TodoCheckButton extends StatelessWidget {
  const TodoCheckButton({
    super.key,
    required this.isCompleted,
    required this.onChanged,
  });

  final bool isCompleted;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AdaptiveIconButton(
      icon: Icon(
        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isCompleted ? colorScheme.primary : colorScheme.outline,
      ),
      tooltip: isCompleted ? '标记为未完成' : '标记为完成',
      onPressed: onChanged,
    );
  }
}