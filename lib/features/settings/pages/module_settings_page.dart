import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/modules/module_contract.dart';
import 'package:ametoolbox/core/providers/module_provider.dart';
import 'package:ametoolbox/shared/utils/module_icon_mapper.dart';
import 'package:ametoolbox/shared/widgets/adaptive_list_tile.dart';
import 'package:ametoolbox/shared/widgets/md3_switch.dart';

/// 模块设置页。
///
/// 列出所有已注册模块，支持单独启用/停用每个模块。
class ModuleSettingsPage extends ConsumerWidget {
  const ModuleSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moduleController = ref.watch(moduleControllerProvider);
    final modules = moduleController.registeredModules;

    return Scaffold(
      appBar: AppBar(title: const Text('模块设置')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final module = modules[index];
          final enabled = moduleController.isEnabled(module.definition.id);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: AdaptiveListTile(
              leading: Icon(ModuleIconMapper.map(module.definition.iconName)),
              title: Text(module.definition.name),
              subtitle: module.definition.description != null
                  ? Text(module.definition.description!)
                  : null,
              trailing: Md3Switch(
                value: enabled,
                onChanged: (_) => moduleController.toggleModule(module.definition.id),
              ),
              onTap: () => _openModuleSettings(context, module, ref),
            ),
          );
        },
      ),
    );
  }

  void _openModuleSettings(
    BuildContext context,
    ModuleContract module,
    WidgetRef ref,
  ) {
    final settingsPage = module.buildSettingsPage(context, ref);
    if (settingsPage != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => settingsPage),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${module.definition.name} 暂无专属设置页')),
      );
    }
  }
}
