import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/constants.dart';
import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_summary.dart';
import 'package:ametoolbox/core/modules/module_contract.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

/// 模块注册表——底座启动时扫描并注册所有模块。
///
/// 子项目开发完成后，将对应模块实例追加到 [registerAll] 列表中。
class ModuleRegistry {
  const ModuleRegistry._();

  /// 注册所有内置模块。
  ///
  /// 当前为三个首版模块的占位实现；子项目 SUB-01/02/03 开发完成后替换为真实模块。
  static List<ModuleContract> registerAll() {
    return [
      _PlaceholderModule(
        definition: _toDefinition(AppConstants.defaultModules[0]),
      ),
      _PlaceholderModule(
        definition: _toDefinition(AppConstants.defaultModules[1]),
      ),
      _PlaceholderModule(
        definition: _toDefinition(AppConstants.defaultModules[2]),
      ),
    ];
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
