import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_module/features/calculator/models/calculation_history.dart';
import 'package:calculator_module/features/calculator/models/calculator_config.dart';
import 'package:calculator_module/features/calculator/models/calculator_type.dart';

void main() {
  group('CalculatorConfig', () {
    test('默认构造包含正确默认值', () {
      const config = CalculatorConfig();

      expect(config.currentType, CalculatorType.scientific);
      expect(config.decimalPrecision, 6);
      expect(config.showFullKeyboard, true);
      expect(config.scientificNotation, false);
      expect(config.historyPanelOnLeft, false);
      expect(config.dashboardQuickCalc, true);
      expect(config.dashboardHistory, true);
      expect(config.exchangeRateApiUrl,
          'https://open.er-api.com/v6/latest/{base}');
      expect(config.history, isEmpty);
      expect(config.exchangeRates, isNull);
    });

    test('JSON 序列化 / 反序列化往返一致', () {
      final now = DateTime.utc(2026, 7, 31, 12, 0, 0);
      final config = CalculatorConfig(
        currentType: CalculatorType.geometry,
        decimalPrecision: 4,
        scientificNotation: true,
        showFullKeyboard: false,
        history: [
          CalculationHistory(
            expression: '1+1',
            result: '2',
            timestamp: now,
            angleMode: 'RAD',
            calculatorType: CalculatorType.scientific,
          ),
        ],
      );

      final json = config.toJson();
      final restored = CalculatorConfig.fromJson(json);

      expect(restored.currentType, config.currentType);
      expect(restored.decimalPrecision, config.decimalPrecision);
      expect(restored.scientificNotation, config.scientificNotation);
      expect(restored.showFullKeyboard, config.showFullKeyboard);
      expect(restored.history.length, 1);
      expect(restored.history.first.expression, '1+1');
      expect(restored.history.first.angleMode, 'RAD');
      expect(restored.history.first.calculatorType,
          CalculatorType.scientific);
      expect(restored, config);
    });

    test('copyWith 修改单个字段不影响其他字段', () {
      const config = CalculatorConfig();
      final updated = config.copyWith(decimalPrecision: 8);

      expect(updated.decimalPrecision, 8);
      expect(updated.currentType, config.currentType);
      expect(updated.showFullKeyboard, config.showFullKeyboard);
      expect(updated.scientificNotation, config.scientificNotation);
    });

    test('历史记录超过 20 条时由 Controller 截断', () {
      // 注：截断逻辑在 CalculatorConfigController.addHistory 中实现，
      // 此处验证模型本身可容纳任意长度列表。
      final history = List.generate(
        25,
        (i) => CalculationHistory(
          expression: '$i',
          result: '$i',
          timestamp: DateTime.utc(2026, 1, 1),
        ),
      );
      final config = CalculatorConfig(history: history);
      expect(config.history.length, 25);
    });
  });
}
