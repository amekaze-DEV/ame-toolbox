import 'package:flutter/material.dart';

import 'package:ametoolbox/core/models/module_summary.dart';
import 'package:ametoolbox/shared/utils/module_icon_mapper.dart';

/// 主页模块摘要卡片。
///
/// 触控模式下使用较高卡片以方便点击，键鼠模式下保持紧凑。
class ModuleCard extends StatelessWidget {
  const ModuleCard({
    super.key,
    required this.iconName,
    required this.name,
    required this.summary,
    required this.onTap,
  });

  final String iconName;
  final String name;
  final ModuleSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    ModuleIconMapper.map(iconName),
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary.label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                summary.unit != null && summary.unit!.isNotEmpty
                    ? '${summary.value} ${summary.unit}'
                    : summary.value,
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
