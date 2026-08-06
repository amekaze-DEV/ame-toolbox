import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_module/features/calculator/data/calculator_config_repository.dart';
import 'package:calculator_module/features/calculator/models/calculator_type.dart';
import 'package:calculator_module/features/calculator/models/gas_type.dart';
import 'package:calculator_module/features/calculator/providers/calculator_config_controller.dart';
import 'package:calculator_module/features/calculator/providers/standard_cubic_mass_controller.dart';
import 'package:calculator_module/features/calculator/services/standard_cubic_mass_service.dart';

import '../helpers/fake_storage_service.dart';

void main() {
  late FakeStorageService storage;
  late CalculatorConfigController configController;
  late StandardCubicMassController controller;

  setUp(() {
    storage = FakeStorageService();
    configController = CalculatorConfigController(
      repository: CalculatorConfigRepository(storage: storage),
    );
    controller = StandardCubicMassController(
      service: const StandardCubicMassService(),
      configController: configController,
    );
  });

  group('StandardCubicMassController', () {
    test('默认气体为天然气，默认 Vm 为 22.414', () {
      expect(controller.gasType, GasType.naturalGas);
      expect(controller.vm, '22.414');
      expect(controller.density, isNotEmpty);
    });

    test('甲烷 1 Nm³ 换算为约 0.715624 kg', () {
      controller.setVolumeValue('1');
      expect(controller.massValue, '0.715624');
      expect(controller.error, isNull);
    });

    test('空气 1 kg 换算为约 0.773697 Nm³', () {
      controller.setGasType(GasType.air);
      controller.setMassValue('1');
      expect(controller.volumeValue, '0.773697');
      expect(controller.error, isNull);
    });

    test('切换为自定义气体后显示摩尔质量输入', () {
      controller.setGasType(GasType.custom);
      expect(controller.isCustom, true);
      controller.setCustomMolarMass('44.01');
      controller.setVolumeValue('1');
      expect(controller.massValue, isNotEmpty);
    });

    test('默认转换方向为 volumeToMass', () {
      expect(controller.direction, StandardCubicMassDirection.volumeToMass);
    });

    test('setDirection 切换方向并同步更新活跃字段', () {
      controller.setDirection(StandardCubicMassDirection.massToVolume);
      expect(controller.direction, StandardCubicMassDirection.massToVolume);
      expect(controller.activeField, 'mass');
    });

    test('swapDirection 切换方向', () {
      controller.swapDirection();
      expect(controller.direction, StandardCubicMassDirection.massToVolume);
      controller.swapDirection();
      expect(controller.direction, StandardCubicMassDirection.volumeToMass);
    });

    test('质量转体积模式下编辑体积自动切换方向', () {
      controller.setDirection(StandardCubicMassDirection.massToVolume);
      controller.setVolumeValue('1');
      expect(controller.direction, StandardCubicMassDirection.volumeToMass);
    });

    test('体积转质量模式下编辑质量自动切换方向', () {
      controller.setVolumeValue('1');
      controller.setMassValue('0.5');
      expect(controller.direction, StandardCubicMassDirection.massToVolume);
    });

    test('负体积显示校验错误', () {
      controller.setVolumeValue('-1');
      expect(controller.error, '标准体积必须大于或等于 0');
    });

    test('清空后输入为空', () {
      controller.setVolumeValue('1');
      controller.clear();
      expect(controller.volumeValue, '');
      expect(controller.massValue, '');
      expect(controller.error, isNull);
    });

    test('默认活跃字段为 volume', () {
      expect(controller.activeField, 'volume');
    });

    test('小键盘 append 向活跃字段追加数字', () {
      controller.append('1');
      controller.append('.');
      controller.append('5');
      expect(controller.volumeValue, '1.5');
      expect(controller.massValue, isNotEmpty);
    });

    test('切换活跃字段后 append 目标字段', () {
      controller.setActiveField('mass');
      controller.append('2');
      expect(controller.massValue, '2');
      expect(controller.volumeValue, isNotEmpty);
    });

    test('小键盘 backspace 删除活跃字段末位', () {
      controller.setVolumeValue('12');
      controller.backspace();
      expect(controller.volumeValue, '1');
    });

    test('小键盘 clear 清空输入', () {
      controller.setVolumeValue('1');
      controller.clear();
      expect(controller.volumeValue, '');
      expect(controller.massValue, '');
    });

    test('自定义气体时 editableFields 包含 customMolarMass', () {
      controller.setGasType(GasType.custom);
      expect(controller.editableFields, contains('customMolarMass'));
    });

    test('saveToHistory 元数据包含 direction', () async {
      controller.setVolumeValue('1');
      await controller.saveToHistory();

      final history = configController.config.history;
      expect(history, isNotEmpty);
      final record = history.last;
      expect(record.calculatorType, CalculatorType.standardCubicToMass);
      expect(record.metadata?['direction'], 'volumeToMass');
      expect(record.metadata?['vm'], '22.414');
    });

    test('massToVolume 方向保存历史元数据正确', () async {
      controller.setMassValue('1');
      expect(controller.direction, StandardCubicMassDirection.massToVolume);
      await controller.saveToHistory();

      final history = configController.config.history;
      expect(history.last.metadata?['direction'], 'massToVolume');
    });
  });
}
