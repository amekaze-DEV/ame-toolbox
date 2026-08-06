import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_module/features/calculator/data/calculator_config_repository.dart';
import 'package:calculator_module/features/calculator/models/calculator_type.dart';
import 'package:calculator_module/features/calculator/providers/calculator_config_controller.dart';
import 'package:calculator_module/features/calculator/providers/radix_converter_controller.dart';
import 'package:calculator_module/features/calculator/services/radix_converter_service.dart';

import '../helpers/fake_storage_service.dart';

void main() {
  group('RadixConverterController', () {
    late FakeStorageService storage;
    late CalculatorConfigController configController;
    late RadixConverterController controller;

    setUp(() async {
      storage = FakeStorageService();
      configController = CalculatorConfigController(
        repository: CalculatorConfigRepository(storage: storage),
      );
      controller = RadixConverterController(
        service: RadixConverterService(),
        configController: configController,
      );
    });

    test('初始状态所有进制输入为空', () {
      expect(controller.values.values, everyElement(''));
      expect(controller.activeType, RadixType.decimal);
    });

    test('设置十进制值后同步其他进制', () {
      controller.setValue(RadixType.decimal, '10');
      expect(controller.values[RadixType.decimal], '10');
      expect(controller.values[RadixType.binary], '0b1010');
      expect(controller.values[RadixType.octal], '0o12');
      expect(controller.values[RadixType.hex], '0xA');
    });

    test('设置二进制值后同步其他进制', () {
      controller.setValue(RadixType.binary, '0b1010');
      expect(controller.values[RadixType.decimal], '10');
      expect(controller.values[RadixType.octal], '0o12');
      expect(controller.values[RadixType.hex], '0xA');
    });

    test('设置二进制 1 后各进制格式正确', () {
      controller.setValue(RadixType.binary, '1');
      expect(controller.values[RadixType.binary], '1');
      expect(controller.values[RadixType.octal], '0o1');
      expect(controller.values[RadixType.decimal], '1');
      expect(controller.values[RadixType.hex], '0x1');
    });

    test('清空后所有输入为空', () {
      controller.setValue(RadixType.decimal, '10');
      controller.clear();
      expect(controller.values.values, everyElement(''));
    });

    test('保存历史记录写入元数据', () async {
      controller.setValue(RadixType.decimal, '10');
      await controller.saveToHistory();

      expect(configController.config.history, hasLength(1));
      final record = configController.config.history.first;
      expect(record.calculatorType, CalculatorType.radix);
      expect(record.metadata?['activeType'], 'decimal');
      expect(record.metadata?['values'], isA<Map<String, dynamic>>());
    });

    test('空输入时不写入历史记录', () async {
      await controller.saveToHistory();
      expect(configController.config.history, isEmpty);
    });

    group('键盘操作', () {
      test('append 向活跃进制输入追加字符', () {
        controller.setActiveType(RadixType.binary);
        controller.append('1');
        controller.append('0');
        controller.append('1');
        expect(controller.values[RadixType.binary], '0b101');
        expect(controller.values[RadixType.decimal], '5');
      });

      test('二进制 append 忽略非法字符由键盘控制，服务正常格式化', () {
        controller.setActiveType(RadixType.hex);
        controller.append('A');
        controller.append('F');
        expect(controller.values[RadixType.hex], '0xAF');
        expect(controller.values[RadixType.decimal], '175');
      });

      test('backspace 删除活跃进制输入的最后一位', () {
        controller.setValue(RadixType.decimal, '123');
        controller.backspace();
        expect(controller.values[RadixType.decimal], '12');
        expect(controller.values[RadixType.binary], '0b1100');
      });

      test('清空后再 backspace 无效果', () {
        controller.clear();
        controller.backspace();
        expect(controller.values.values, everyElement(''));
      });

      test('toggleSign 切换十进制正负号', () {
        controller.setActiveType(RadixType.decimal);
        controller.append('1');
        controller.append('0');
        controller.toggleSign();
        expect(controller.values[RadixType.decimal], '-10');
        expect(controller.values[RadixType.binary], startsWith('-0b'));
        controller.toggleSign();
        expect(controller.values[RadixType.decimal], '10');
      });

      test('非十进制 toggleSign 无效', () {
        controller.setActiveType(RadixType.hex);
        controller.append('A');
        controller.toggleSign();
        expect(controller.values[RadixType.hex], '0xA');
      });

      test('空十进制输入 toggleSign 无效果', () {
        controller.setActiveType(RadixType.decimal);
        controller.toggleSign();
        expect(controller.values[RadixType.decimal], '');
      });
    });
  });
}
