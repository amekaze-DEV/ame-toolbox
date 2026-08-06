import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_module/features/calculator/data/calculator_config_repository.dart';
import 'package:calculator_module/features/calculator/models/calculator_type.dart';
import 'package:calculator_module/features/calculator/models/unit_category.dart';
import 'package:calculator_module/features/calculator/providers/calculator_config_controller.dart';
import 'package:calculator_module/features/calculator/providers/unit_converter_controller.dart';
import 'package:calculator_module/features/calculator/services/unit_converter_service.dart';

import '../helpers/fake_storage_service.dart';

void main() {
  late FakeStorageService storage;
  late CalculatorConfigController configController;
  late UnitConverterController controller;

  setUp(() {
    storage = FakeStorageService();
    configController = CalculatorConfigController(
      repository: CalculatorConfigRepository(storage: storage),
    );
    controller = UnitConverterController(
      service: UnitConverterService(),
      configController: configController,
    );
  });

  group('UnitConverterController', () {
    test('默认类别为长度，源单位为 m，目标单位为 km', () {
      expect(controller.category, UnitCategory.length);
      expect(controller.fromUnit, 'm');
      expect(controller.toUnit, 'km');
    });

    test('输入 1000 m 换算为 1 km', () {
      controller.setFromValue('1000');
      expect(controller.result, '1');
      expect(controller.error, isNull);
    });

    test('切换类别后单位和结果重置', () {
      controller.setFromValue('100');
      controller.setCategory(UnitCategory.weight);
      expect(controller.category, UnitCategory.weight);
      expect(controller.fromValue, '');
      expect(controller.result, '');
    });

    test('交换单位会把结果作为新源数值', () {
      controller.setFromValue('1');
      expect(controller.result, '0.001');
      controller.swap();
      expect(controller.fromUnit, 'km');
      expect(controller.toUnit, 'm');
      expect(controller.fromValue, '0.001');
      expect(controller.result, '1');
    });

    test('无效输入显示错误', () {
      controller.setFromValue('abc');
      expect(controller.error, '请输入有效数字');
    });

    test('清空后输入与结果为空', () {
      controller.setFromValue('100');
      controller.clear();
      expect(controller.fromValue, '');
      expect(controller.result, '');
      expect(controller.error, isNull);
    });

    test('温度类别使用自研公式：0°C = 32°F', () {
      controller.setCategory(UnitCategory.temperature);
      controller.setFromValue('0');
      controller.setFromUnit('°C');
      controller.setToUnit('°F');
      expect(controller.result, '32');
    });

    test('记录按钮将当前结果写入历史记录', () async {
      controller.setFromValue('1000');
      expect(controller.result, '1');

      await controller.saveToHistory();

      expect(configController.config.history, hasLength(1));
      final record = configController.config.history.first;
      expect(record.calculatorType, CalculatorType.unitConverter);
      expect(record.expression, '1000 m = 1 km');
      expect(record.result, '1 km');
      expect(record.metadata?['category'], 'length');
      expect(record.metadata?['fromUnit'], 'm');
      expect(record.metadata?['toUnit'], 'km');
    });

    test('结果为空时不写入历史记录', () async {
      await controller.saveToHistory();
      expect(configController.config.history, isEmpty);
    });

    test('错误结果不写入历史记录', () async {
      controller.setFromValue('abc');
      expect(controller.error, isNotNull);
      await controller.saveToHistory();
      expect(configController.config.history, isEmpty);
    });

    test('小键盘 append 可拼接数值', () {
      controller.append('1');
      controller.append('2');
      controller.append('.');
      controller.append('5');
      expect(controller.fromValue, '12.5');
      expect(controller.result, '0.0125');
    });

    test('小键盘 backspace 删除末位', () {
      controller.append('1');
      controller.append('2');
      controller.append('3');
      controller.backspace();
      expect(controller.fromValue, '12');
    });

    test('小键盘 clear 清空输入', () {
      controller.append('1');
      controller.append('2');
      controller.clear();
      expect(controller.fromValue, '');
      expect(controller.result, '');
    });

    test('温度类别下 ± 切换正负号', () {
      controller.setCategory(UnitCategory.temperature);
      controller.append('5');
      controller.append('±');
      expect(controller.fromValue, '-5');
      controller.append('±');
      expect(controller.fromValue, '5');
    });
  });
}
