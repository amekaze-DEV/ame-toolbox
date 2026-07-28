import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/providers/module_provider.dart';
import 'package:ametoolbox/shared/utils/module_icon_mapper.dart';

/// 导航项数据。
class NavItem {
  const NavItem({
    required this.icon,
    required this.label,
    required this.moduleId,
  });

  final IconData icon;
  final String label;
  final String moduleId;
}

/// 当前导航项列表。
///
/// 第一项固定为"主页"，后续项为按 displayOrder 排序后的已启用模块。
final navItemsProvider = Provider<List<NavItem>>((ref) {
  final moduleController = ref.watch(moduleControllerProvider);
  final enabledModules = moduleController.enabledModules;

  return [
    const NavItem(icon: Icons.home_outlined, label: '主页', moduleId: 'home'),
    for (final module in enabledModules)
      NavItem(
        icon: ModuleIconMapper.map(module.definition.iconName),
        label: module.definition.name,
        moduleId: module.definition.id,
      ),
  ];
});
