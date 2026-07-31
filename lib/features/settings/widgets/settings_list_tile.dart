import 'package:flutter/material.dart';

import 'package:ametoolbox/shared/widgets/adaptive_list_tile.dart';

/// 设置页分组列表项。
///
/// 遵循 MD3 规范：ripple 效果、可选 leading/trailing、右侧摘要值。
/// 内部使用 [AdaptiveListTile]，根据触控/键鼠模式自动调整内边距与右键菜单。
class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dense = false,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AdaptiveListTile(
      leading: leading != null
          ? IconTheme(
              data: IconThemeData(color: colorScheme.onSurfaceVariant),
              child: leading!,
            )
          : null,
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
      dense: dense,
    );
  }
}
