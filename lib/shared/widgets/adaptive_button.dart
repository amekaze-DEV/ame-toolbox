import 'package:flutter/material.dart';

import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';

/// 按钮样式变体。
enum AdaptiveButtonVariant {
  filled,
  tonal,
  outlined,
  text,
}

/// 根据输入模式自动调整点击区域与样式的按钮。
///
/// - 触控模式：最小点击区域 48x48 dp，无额外 hover 处理（MD3 按钮本身不带 hover 环）。
/// - 键鼠模式：标准尺寸，MD3 按钮自带 hover 高亮；图标尺寸保持 18dp。
///
/// 不直接使用 [Platform.is*]，仅依赖 [InputModeScope]。
class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    super.key,
    this.onPressed,
    this.label,
    this.icon,
    this.child,
    this.variant = AdaptiveButtonVariant.filled,
    this.style,
  });

  final VoidCallback? onPressed;
  final String? label;
  final IconData? icon;
  final Widget? child;
  final AdaptiveButtonVariant variant;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final isTouch = InputModeScope.of(context) == InputMode.touch;
    final effectiveStyle = _effectiveStyle(context, isTouch);

    final content = child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: isTouch ? 24 : 18),
              const SizedBox(width: 8),
            ],
            Text(label!),
          ],
        );

    return switch (variant) {
      AdaptiveButtonVariant.filled => FilledButton(
          onPressed: onPressed,
          style: effectiveStyle,
          child: content,
        ),
      AdaptiveButtonVariant.tonal => FilledButton.tonal(
          onPressed: onPressed,
          style: effectiveStyle,
          child: content,
        ),
      AdaptiveButtonVariant.outlined => OutlinedButton(
          onPressed: onPressed,
          style: effectiveStyle,
          child: content,
        ),
      AdaptiveButtonVariant.text => TextButton(
          onPressed: onPressed,
          style: effectiveStyle,
          child: content,
        ),
    };
  }

  ButtonStyle _effectiveStyle(BuildContext context, bool isTouch) {
    final minimumSize = isTouch ? const Size(48, 48) : null;

    final base = switch (variant) {
      AdaptiveButtonVariant.filled => FilledButton.styleFrom(
          minimumSize: minimumSize,
        ),
      AdaptiveButtonVariant.tonal => FilledButton.styleFrom(
          minimumSize: minimumSize,
        ),
      AdaptiveButtonVariant.outlined => OutlinedButton.styleFrom(
          minimumSize: minimumSize,
        ),
      AdaptiveButtonVariant.text => TextButton.styleFrom(
          minimumSize: minimumSize,
        ),
    };

    return style == null ? base : base.merge(style);
  }
}

/// 图标型按钮，触控模式下强制 48x48 dp 点击区域。
class AdaptiveIconButton extends StatelessWidget {
  const AdaptiveIconButton({
    super.key,
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.isSelected,
    this.selectedIcon,
  });

  final Widget icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool? isSelected;
  final Widget? selectedIcon;

  @override
  Widget build(BuildContext context) {
    final isTouch = InputModeScope.of(context) == InputMode.touch;

    return IconButton(
      icon: icon,
      tooltip: tooltip,
      isSelected: isSelected,
      selectedIcon: selectedIcon,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: isTouch ? const Size(48, 48) : null,
        tapTargetSize: isTouch ? MaterialTapTargetSize.padded : null,
      ),
    );
  }
}
