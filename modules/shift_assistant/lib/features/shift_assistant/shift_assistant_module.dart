import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_summary.dart';
import 'package:ametoolbox/core/modules/module_contract.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

import 'data/shift_config_repository.dart';
import 'models/shift_config.dart';
import 'pages/shift_assistant_page.dart';
import 'pages/shift_assistant_settings_page.dart';
import 'providers/holiday_data_controller.dart';
import 'providers/shift_config_controller.dart';
import 'services/holiday_data_service.dart';

/// 倒班助手模块。
///
/// 实现 [ModuleContract]，已合并到主项目并在 [ModuleRegistry] 注册。
class ShiftAssistantModule implements ModuleContract {
  ShiftAssistantModule({HolidayDataService? holidayDataService})
      : _holidayDataService = holidayDataService ?? HolidayDataService();

  final HolidayDataService _holidayDataService;

  ShiftConfigRepository? _repository;
  ShiftConfigController? _configController;

  @override
  ModuleDefinition get definition => const ModuleDefinition(
        id: 'shift_assistant',
        name: '倒班助手',
        description: '多班组轮班排班查询、节假日日历与工时统计',
        iconName: 'shift',
        defaultEnabled: true,
      );

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) {
    return const ShiftAssistantPage();
  }

  @override
  Widget? buildSettingsPage(BuildContext context, WidgetRef ref) {
    return const ShiftAssistantSettingsPage();
  }

  @override
  List<Widget> buildDashboardWidgets(BuildContext context, WidgetRef ref) {
    return const [];
  }

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
  ModuleSummary get summary {
    final config = _configController?.config ?? ShiftConfig.defaults();
    final rotation = config.primaryRotation;
    return ModuleSummary(
      label: '主要轮班',
      value: rotation?.name ?? '-',
    );
  }

  @override
  Future<void> initialize(StorageService storage) async {
    _repository = ShiftConfigRepository(storage: storage);
    _configController = ShiftConfigController(repository: _repository!);
    await _configController!.load();

    // 模块启动时触发节假日数据更新检查（失败自动降级，不影响启动）。
    final holidayController = HolidayDataController(
      service: _holidayDataService,
      configController: _configController!,
    );
    await holidayController.checkAndUpdate();
    holidayController.dispose();
  }

  @override
  Future<void> dispose() async {
    _configController?.dispose();
    _configController = null;
    _repository = null;
  }

  @override
  Map<String, dynamic> exportData() {
    final config = _configController?.config ?? ShiftConfig.defaults();
    return {
      'module_shift_assistant_config': config.toJson(),
    };
  }

  @override
  void importData(Map<String, dynamic> data) {
    final configJson =
        data['module_shift_assistant_config'] as Map<String, dynamic>?;
    if (configJson == null) return;

    final config = ShiftConfig.fromJson(configJson);
    _configController?.updateConfig(config);
  }
}
