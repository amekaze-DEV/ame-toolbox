import 'package:flutter/material.dart';

import 'package:ametoolbox/shared/widgets/md3_switch.dart';

/// 设置页分区容器。
///
/// 支持可选的头部开关；子项通过 [children] 传入，统一应用 MD3 分组列表视觉。
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    this.switchValue,
    this.onSwitchChanged,
    this.confirmDismiss,
    required this.children,
  });

  final String title;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final Future<bool> Function()? confirmDismiss;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (switchValue != null)
                Md3Switch(
                  value: switchValue!,
                  onChanged: (value) async {
                    if (!value && confirmDismiss != null) {
                      final confirmed = await confirmDismiss!();
                      if (!confirmed) return;
                    }
                    onSwitchChanged?.call(value);
                  },
                ),
            ],
          ),
        ),
        if (switchValue ?? true)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: children,
            ),
          ),
      ],
    );
  }
}
