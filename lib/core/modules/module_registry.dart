import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/constants.dart';
import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_summary.dart';
import 'package:ametoolbox/core/modules/module_contract.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';
import 'package:calculator_module/features/calculator/calculator_module.dart';
import 'package:shift_assistant_module/features/shift_assistant/shift_assistant_module.dart';

/// 模块注册表——底座启动时扫描并注册所有模块。
///
/// 子项目开发完成后，将对应模块实例追加到 [registerAll] 列表中。
class ModuleRegistry {
  const ModuleRegistry._();

  /// 注册所有内置模块。
  static List<ModuleContract> registerAll() {
    return AppConstants.defaultModules.map((module) {
      final definition = _toDefinition(module);
      return switch (module.id) {
        'calculator' => CalculatorModule(),
        'shift_assistant' => ShiftAssistantModule(),
        _ => _PlaceholderModule(definition: definition),
      };
    }).toList();
  }

  static ModuleDefinition _toDefinition(
    ({String id, String name, String description, String iconName}) module,
  ) {
    return ModuleDefinition(
      id: module.id,
      name: module.name,
      description: module.description,
      iconName: module.iconName,
      defaultEnabled: true,
    );
  }
}

/// 占位模块实现。
///
/// 在子项目交付前提供可运行的模块管理页面与导航栏占位。
class _PlaceholderModule implements ModuleContract {
  _PlaceholderModule({required this.definition});

  @override
  final ModuleDefinition definition;

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(definition.name)),
      body: Center(child: Text('${definition.name} 模块开发中')),
    );
  }

  @override
  Widget? buildSettingsPage(BuildContext context, WidgetRef ref) => null;

  @override
  List<Widget> buildDashboardWidgets(BuildContext context, WidgetRef ref) =>
      const [];

  @override
  bool get hasCustomEntryCard => false;

  @override
  Widget? buildEntryCard(
    BuildContext context,
    WidgetRef ref,
    VoidCallback onOpenModule,
  ) =>
      null;

  @override
  ModuleSummary get summary => ModuleSummary(
        label: definition.name,
        value: '-',
      );

  @override
  Future<void> initialize(StorageService storage) async {}

  @override
  Future<void> dispose() async {}

  @override
  Map<String, dynamic> exportData() => {};

  @override
  void importData(Map<String, dynamic> data) {}
}
