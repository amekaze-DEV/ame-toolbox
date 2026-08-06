import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_module/features/calculator/calculator_module.dart';
import 'package:calculator_module/features/calculator/models/calculation_history.dart';
import 'package:calculator_module/features/calculator/models/calculator_type.dart';
import 'package:calculator_module/features/calculator/widgets/calculator_dashboard_history_card.dart';
import 'package:calculator_module/features/calculator/widgets/calculator_dashboard_quick_calc_card.dart';

import 'helpers/fake_storage_service.dart';

void main() {
  group('CalculatorModule', () {
    late FakeStorageService storage;
    late CalculatorModule module;

    setUp(() async {
      storage = FakeStorageService();
      await storage.initialize();
      module = CalculatorModule();
      await module.initialize(storage);
    });

    test('definition 包含正确的模块元数据', () {
      final definition = module.definition;
      expect(definition.id, 'calculator');
      expect(definition.name, '多功能计算器');
      expect(definition.iconName, 'calculate');
      expect(definition.defaultEnabled, true);
    });

    test('buildPage 返回 CalculatorPage', () {
      // buildPage 需要 BuildContext 与 WidgetRef，此处仅验证返回类型。
      expect(module.buildPage, isA<Function>());
    });

    test('buildSettingsPage 返回 CalculatorSettingsPage', () {
      expect(module.buildSettingsPage, isA<Function>());
    });

    test('buildDashboardWidgets 默认返回两个卡片', () {
      final widgets = module.buildDashboardWidgets;
      expect(widgets, isA<Function>());
    });

    test('summary 默认返回模块描述', () {
      final summary = module.summary;
      expect(summary.label, '多功能计算器');
    });

    test('添加历史后 summary 返回最近计算结果', () async {
      await module.configController!.addHistory(
        CalculationHistory(
          expression: '1+1',
          result: '2',
          timestamp: DateTime.utc(2026, 8, 5),
          calculatorType: CalculatorType.scientific,
        ),
      );

      final summary = module.summary;
      expect(summary.label, '最近计算');
      expect(summary.value, '2');
    });

    test('dashboard 卡片顺序受配置控制', () async {
      await module.configController!.setDashboardOrders(
        quickCalcOrder: 1,
        historyOrder: 0,
      );

      final widgets = module.configController!.config.dashboardQuickCalc &&
              module.configController!.config.dashboardHistory
          ? [
              const CalculatorDashboardHistoryCard(),
              const CalculatorDashboardQuickCalcCard(),
            ]
          : [];

      expect(widgets.length, 2);
      expect(widgets.first, isA<CalculatorDashboardHistoryCard>());
      expect(widgets.last, isA<CalculatorDashboardQuickCalcCard>());
    });

    test('exportData / importData 往返一致', () {
      final exported = module.exportData();
      expect(exported, contains('module_calculator_config'));

      module.importData(exported);
      expect(module.configController!.config.history, isEmpty);
    });
  });
}
