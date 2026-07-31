import 'package:flutter/material.dart';

import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';

/// 根据输入模式自动调整点击区域与内边距的列表项。
///
/// - 触控模式：`minVerticalPadding: 16`，高度更宽松，便于手指点击。
/// - 键鼠模式：`minVerticalPadding: 8`，更紧凑；支持右键菜单与 hover 高亮。
///
/// 不直接使用 [Platform.is*]，仅依赖 [InputModeScope]。
class AdaptiveListTile extends StatelessWidget {
  const AdaptiveListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.contextMenuBuilder,
    this.dense = false,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final List<PopupMenuEntry<void>> Function(BuildContext context)?
      contextMenuBuilder;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final inputMode = InputModeScope.of(context);
    final isTouch = inputMode == InputMode.touch;

    Widget tile = ListTile(
      leading: leading != null
          ? IconTheme(
              data: IconThemeData(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              child: leading!,
            )
          : null,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      dense: dense,
      minVerticalPadding: isTouch ? 16 : 8,
    );

    // 键鼠模式右键菜单，触控模式长按菜单。
    if (contextMenuBuilder != null) {
      tile = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onSecondaryTapDown: inputMode == InputMode.mouse
            ? (details) => _showContextMenu(context, details.globalPosition)
            : null,
        onLongPressStart: isTouch
            ? (details) => _showContextMenu(context, details.globalPosition)
            : null,
        child: tile,
      );
    } else if (onLongPress != null) {
      tile = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: onLongPress,
        child: tile,
      );
    }

    return tile;
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final items = contextMenuBuilder?.call(context);
    if (items == null || items.isEmpty) return;

    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: items,
    );
  }
}
