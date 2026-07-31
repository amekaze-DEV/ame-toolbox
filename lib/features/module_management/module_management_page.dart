import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/providers/module_provider.dart';
import 'package:ametoolbox/shared/widgets/adaptive_list_tile.dart';
import 'package:ametoolbox/shared/widgets/md3_switch.dart';

/// 模块管理页面。
///
/// 展示所有可用模块，用户可通过 Switch 启用/关闭各模块。
/// 开关状态与 [ModuleState.enabled] 双向绑定并即时持久化。
class ModuleManagementPage extends ConsumerWidget {
  const ModuleManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(moduleControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final modules = controller.registeredModules;

    return Scaffold(
      appBar: AppBar(
        title: const Text('模块管理'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: modules.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final module = modules[index];
                final definition = module.definition;
                final enabled = controller.isEnabled(definition.id);

                return _ModuleListTile(
                  definition: definition,
                  enabled: enabled,
                  onToggle: (_) => controller.toggleModule(definition.id),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Text(
                '当前已启用 ${controller.enabledCount} 个模块',
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleListTile extends StatelessWidget {
  const _ModuleListTile({
    required this.definition,
    required this.enabled,
    required this.onToggle,
  });

  final ModuleDefinition definition;
  final bool enabled;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AdaptiveListTile(
      leading: Icon(
        _iconFor(definition.iconName),
        color: enabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(definition.name),
      subtitle: definition.description != null
          ? Text(
              definition.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Md3Switch(
        value: enabled,
        onChanged: onToggle,
      ),
    );
  }

  IconData _iconFor(String iconName) {
    return switch (iconName) {
      'counter' => Icons.plus_one,
      'timer' => Icons.timer_outlined,
      'checklist' => Icons.checklist_outlined,
      _ => Icons.widgets_outlined,
    };
  }
}
