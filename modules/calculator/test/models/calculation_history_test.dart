import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_module/features/calculator/models/calculation_history.dart';
import 'package:calculator_module/features/calculator/models/calculator_type.dart';

void main() {
  group('CalculationHistory', () {
    test('默认构造包含正确的默认值', () {
      final record = CalculationHistory(
        expression: '1+1',
        result: '2',
        timestamp: _testTime,
      );

      expect(record.expression, '1+1');
      expect(record.result, '2');
      expect(record.isError, false);
      expect(record.angleMode, 'DEG');
      expect(record.calculatorType, CalculatorType.scientific);
    });

    test('copyWith 可修改 calculatorType', () {
      final record = CalculationHistory(
        expression: '1+1',
        result: '2',
        timestamp: _testTime,
      );
      final updated = record.copyWith(
        calculatorType: CalculatorType.geometry,
      );

      expect(updated.calculatorType, CalculatorType.geometry);
      expect(updated.expression, record.expression);
      expect(updated.result, record.result);
    });

    test('JSON 序列化 / 反序列化往返一致', () {
      final record = CalculationHistory(
        expression: '1+1',
        result: '2',
        timestamp: _testTime,
        angleMode: 'RAD',
        calculatorType: CalculatorType.unitConverter,
      );

      final json = record.toJson();
      final restored = CalculationHistory.fromJson(json);

      expect(restored, record);
      expect(restored.calculatorType, CalculatorType.unitConverter);
    });

    test('calculatorType 不同的两条记录不相等', () {
      final base = CalculationHistory(
        expression: '1+1',
        result: '2',
        timestamp: _testTime,
      );
      final other = base.copyWith(
        calculatorType: CalculatorType.geometry,
      );

      expect(base, isNot(other));
      expect(base.hashCode, isNot(other.hashCode));
    });

    test('旧数据缺失 calculatorType 时兼容反序列化为 scientific', () {
      final record = CalculationHistory.fromJson({
        'expression': '1+1',
        'result': '2',
        'timestamp': '2026-07-31T12:00:00.000Z',
        'isError': false,
        'angleMode': 'DEG',
      });

      expect(record.calculatorType, CalculatorType.scientific);
    });

    test('metadata 字段可序列化与反序列化', () {
      final record = CalculationHistory(
        expression: '1 m = 1000 mm',
        result: '1000 mm',
        timestamp: _testTime,
        calculatorType: CalculatorType.unitConverter,
        metadata: {
          'category': 'length',
          'fromValue': '1',
          'fromUnit': 'm',
          'toUnit': 'mm',
        },
      );

      final json = record.toJson();
      final restored = CalculationHistory.fromJson(json);

      expect(restored, record);
      expect(restored.metadata?['fromUnit'], 'm');
    });
  });
}

final _testTime = DateTime.utc(2026, 7, 31, 12, 0, 0);
