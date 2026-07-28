import 'package:flutter/material.dart';

/// Material Design 3 风格的 Switch 组件。
///
/// 封装 [Switch]，提供统一的过渡时长与最小点击区域。
/// 触控/键鼠尺寸差异将在 TASK-08 输入模式适配中扩展。
class Md3Switch extends StatelessWidget {
  const Md3Switch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  /// 当前开关状态。
  final bool value;

  /// 状态变更回调。
  final ValueChanged<bool>? onChanged;

  /// 激活态颜色；为 null 时使用主题 [ColorScheme.primary]。
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      toggled: value,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: SizedBox(
          width: 56,
          height: 48,
          child: Center(
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: activeColor ?? colorScheme.primary,
              inactiveThumbColor: colorScheme.outline,
              inactiveTrackColor: colorScheme.surfaceContainerHighest,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ),
    );
  }
}
