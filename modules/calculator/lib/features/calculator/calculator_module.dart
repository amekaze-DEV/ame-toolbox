import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_summary.dart';
import 'package:ametoolbox/core/modules/module_contract.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

import 'pages/calculator_page.dart';

/// 多功能计算器模块。
///
/// 实现 [ModuleContract]，可在隔离环境中独立运行，
/// 开发完成后直接合并到主项目并注册到 [ModuleRegistry]。
class CalculatorModule implements ModuleContract {
  CalculatorModule();

  List<Map<String, dynamic>> _history = [];

  @override
  ModuleDefinition get definition => const ModuleDefinition(
        id: 'calculator',
        name: '多功能计算器',
        description: '表达式计算与历史记录',
        iconName: 'calculator',
        defaultEnabled: true,
      );

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) {
    return const CalculatorPage();
  }

  @override
  Widget? buildSettingsPage(BuildContext context, WidgetRef ref) => null;

  @override
  ModuleSummary get summary {
    final lastResult = _history.isNotEmpty ? _history.first['result'] : '-';
    return ModuleSummary(
      label: '最近计算',
      value: lastResult as String,
    );
  }

  @override
  Future<void> initialize(StorageService storage) async {
    final data = await storage.loadData('calculator_history');
    _history = (data?['history'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }

  @override
  Future<void> dispose() async {}

  @override
  Map<String, dynamic> exportData() => {
        'calculator_history': {'history': _history},
      };

  @override
  void importData(Map<String, dynamic> data) {
    _history = (data['calculator_history']?['history'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }
}
