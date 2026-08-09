import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_summary.dart';
import 'package:ametoolbox/core/modules/module_contract.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

import 'data/calculator_config_repository.dart';
import 'models/calculator_config.dart';
import 'pages/calculator_page.dart';
import 'pages/calculator_settings_page.dart';
import 'providers/calculator_config_controller.dart';
import 'widgets/calculator_dashboard_quick_calc_card.dart';

/// 多功能计算器模块。
///
/// 实现 [ModuleContract]，可在隔离环境中独立运行，
/// 开发完成后直接合并到主项目并注册到 [ModuleRegistry]。
class CalculatorModule implements ModuleContract {
  CalculatorModule();

  CalculatorConfigRepository? _repository;
  CalculatorConfigController? _configController;

  /// 暴露内部配置控制器，供独立运行入口覆盖 [calculatorConfigProvider] 使用，
  /// 确保模块契约与 UI 层共享同一状态实例。
  CalculatorConfigController? get configController => _configController;

  @override
  ModuleDefinition get definition => const ModuleDefinition(
        id: 'calculator',
        name: '多功能计算器',
        description: '表达式计算、单位换算、几何与汇率计算',
        iconName: 'calculator',
        defaultEnabled: true,
      );

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) {
    return const CalculatorPage();
  }

  @override
  Widget? buildSettingsPage(BuildContext context, WidgetRef ref) {
    return const CalculatorSettingsPage();
  }

  @override
  List<Widget> buildDashboardWidgets(BuildContext context, WidgetRef ref) {
    return const [];
  }

  @override
  bool get hasCustomEntryCard =>
      _configController?.config.dashboardQuickCalc ?? true;

  @override
  Widget? buildEntryCard(
    BuildContext context,
    WidgetRef ref,
    VoidCallback onOpenModule,
  ) {
    if (!(_configController?.config.dashboardQuickCalc ?? true)) return null;
    return CalculatorDashboardQuickCalcCard(onOpenModule: onOpenModule);
  }

  @override
  ModuleSummary get summary {
    final config = _configController?.config ?? CalculatorConfig.defaults;
    final history = config.history;
    if (history.isEmpty) {
      return const ModuleSummary(
        label: '多功能计算器',
        value: '科学计算、单位换算、几何与汇率',
      );
    }
    return ModuleSummary(
      label: '最近计算',
      value: history.first.result,
    );
  }

  @override
  Future<void> initialize(StorageService storage) async {
    _repository = CalculatorConfigRepository(storage: storage);
    _configController = CalculatorConfigController(repository: _repository!);
    await _configController!.load();
  }

  @override
  Future<void> dispose() async {
    _configController?.dispose();
    _configController = null;
    _repository = null;
  }

  @override
  Map<String, dynamic> exportData() {
    final config = _configController?.config ?? CalculatorConfig.defaults;
    return {
      'module_calculator_config': config.toJson(),
    };
  }

  @override
  void importData(Map<String, dynamic> data) {
    final configJson = data['module_calculator_config'] as Map<String, dynamic>?;
    if (configJson == null) return;

    final config = CalculatorConfig.fromJson(configJson);
    _configController?.updateConfig(config);
  }
}
