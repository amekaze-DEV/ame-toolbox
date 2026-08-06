import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_module/features/calculator/data/calculator_config_repository.dart';
import 'package:calculator_module/features/calculator/models/calculator_type.dart';
import 'package:calculator_module/features/calculator/models/geometry_shape.dart';
import 'package:calculator_module/features/calculator/models/unit_category.dart';
import 'package:calculator_module/features/calculator/providers/calculator_config_controller.dart';
import 'package:calculator_module/features/calculator/providers/geometry_controller.dart';
import 'package:calculator_module/features/calculator/services/geometry_service.dart';
import 'package:calculator_module/features/calculator/services/unit_converter_service.dart';

import '../helpers/fake_storage_service.dart';

void main() {
  late FakeStorageService storage;
  late CalculatorConfigController configController;
  late GeometryController controller;

  setUp(() {
    storage = FakeStorageService();
    configController = CalculatorConfigController(
      repository: CalculatorConfigRepository(storage: storage),
    );
    controller = GeometryController(
      service: GeometryService(),
      unitService: UnitConverterService(),
      configController: configController,
    );
  });

  group('GeometryController', () {
    test('默认几何体为圆', () {
      expect(controller.shape, GeometryShape.circle);
      expect(controller.inputFields, ['r']);
    });

    test('输入 r=1 后计算面积和周长', () {
      controller.setInput('r', '1');
      expect(controller.error, isNull);
      expect(controller.results['面积'], '3.141593');
      expect(controller.results['周长'], '6.283185');
    });

    test('输入单位 cm 时按米基准计算', () {
      controller.setInputUnit('r', 'cm');
      controller.setInput('r', '100');
      expect(controller.results['面积'], '3.141593');
      expect(controller.results['周长'], '6.283185');
    });

    test('输出单位 km² 时面积转换正确', () {
      controller.setInput('r', '1000');
      controller.setOutputUnit('面积', 'km²');
      expect(controller.results['面积'], '3.141593');
      expect(controller.results['周长'], '6283.185307');
    });

    test('切换几何体清空输入与结果', () {
      controller.setInput('r', '1');
      controller.setShape(GeometryShape.rectangle);
      expect(controller.inputs, isEmpty);
      expect(controller.results, isEmpty);
      expect(controller.inputFields, ['a', 'b']);
    });

    test('切换为长方体后输出单位变为体积单位', () {
      controller.setShape(GeometryShape.cuboid);
      expect(controller.outputUnit('体积'), 'm³');
      expect(controller.outputUnits('体积'), UnitCategory.volume.units);
      expect(controller.outputUnit('表面积'), 'm²');
      expect(controller.outputUnits('表面积'), UnitCategory.area.units);
    });

    test('矩形 a=3 b=4 计算正确', () {
      controller.setShape(GeometryShape.rectangle);
      controller.setInput('a', '3');
      controller.setInput('b', '4');
      expect(controller.results['面积'], '12');
      expect(controller.results['周长'], '14');
      expect(controller.results['对角线'], '5');
    });

    test('圆锥 r=3 h=4 自动计算 l=5', () {
      controller.setShape(GeometryShape.cone);
      controller.setInput('r', '3');
      controller.setInput('h', '4');
      expect(controller.error, isNull);
      expect(controller.results['体积'], '37.699112');
      expect(controller.results['侧面积'], '47.12389');
    });

    test('圆锥 r=3 l=5 自动计算 h=4', () {
      controller.setShape(GeometryShape.cone);
      controller.setInput('r', '3');
      controller.setInput('l', '5');
      expect(controller.error, isNull);
      expect(controller.results['体积'], '37.699112');
    });

    test('圆锥只输入一个参数时不计算', () {
      controller.setShape(GeometryShape.cone);
      controller.setInput('r', '3');
      expect(controller.results, isEmpty);
      expect(controller.error, isNull);
    });

    test('圆锥三个参数不一致时报错', () {
      controller.setShape(GeometryShape.cone);
      controller.setInput('r', '3');
      controller.setInput('h', '4');
      controller.setInput('l', '6');
      expect(controller.error, contains('母线长 l 必须满足'));
    });

    test('圆筒 R<=r 显示校验错误', () {
      controller.setShape(GeometryShape.hollowCylinder);
      controller.setInput('R', '2');
      controller.setInput('r', '3');
      controller.setInput('h', '5');
      expect(controller.error, '圆筒外径 R 必须大于内径 r');
    });

    test('棱锥 n=2 显示校验错误', () {
      controller.setShape(GeometryShape.pyramid);
      controller.setInput('n', '2');
      controller.setInput('a', '1');
      controller.setInput('h', '1');
      expect(controller.error, '棱锥底边数 n 必须大于等于 3 且为整数');
    });

    test('清空后输入与结果为空', () {
      controller.setInput('r', '1');
      controller.clear();
      expect(controller.inputs, isEmpty);
      expect(controller.results, isEmpty);
    });

    test('默认活跃字段为第一个输入字段', () {
      expect(controller.activeField, 'r');
    });

    test('切换几何体后活跃字段更新为第一个字段', () {
      controller.setShape(GeometryShape.rectangle);
      expect(controller.activeField, 'a');
    });

    test('小键盘 append 向活跃字段追加数字', () {
      controller.append('1');
      controller.append('.');
      controller.append('5');
      expect(controller.inputs['r'], '1.5');
      expect(controller.results['面积'], isNotNull);
    });

    test('设置活跃字段后 append 目标字段', () {
      controller.setShape(GeometryShape.rectangle);
      controller.setActiveField('b');
      controller.append('4');
      expect(controller.inputs['b'], '4');
      expect(controller.inputs['a'], isNull);
    });

    test('小键盘 backspace 删除活跃字段末位', () {
      controller.setInput('r', '12');
      controller.backspace();
      expect(controller.inputs['r'], '1');
    });

    test('小键盘 clear 清空所有输入', () {
      controller.setInput('r', '1');
      controller.clear();
      expect(controller.inputs, isEmpty);
      expect(controller.results, isEmpty);
    });

    test('保存历史记录写入元数据', () async {
      controller.setInput('r', '1');
      controller.setInputUnit('r', 'cm');
      controller.setOutputUnit('面积', 'km²');
      await controller.saveToHistory();

      expect(configController.config.history, hasLength(1));
      final record = configController.config.history.first;
      expect(record.calculatorType, CalculatorType.geometry);
      expect(record.metadata?['shape'], 'circle');
      expect(record.metadata?['inputs'], {'r': '1'});
      expect(record.metadata?['inputUnits'], {'r': 'cm'});
      expect(record.metadata?['outputUnits'], {'面积': 'km²'});
    });

    test('无计算结果时不写入历史记录', () async {
      await controller.saveToHistory();
      expect(configController.config.history, isEmpty);
    });

    test('每个输入字段可独立设定输入单位', () {
      controller.setShape(GeometryShape.rectangle);
      controller.setInputUnit('a', 'cm');
      controller.setInputUnit('b', 'm');
      controller.setInput('a', '100');
      controller.setInput('b', '1');
      // a=100cm=1m, b=1m -> 面积=1m², 周长=4m, 对角线=√2m
      expect(controller.results['面积'], '1');
      expect(controller.results['周长'], '4');
      expect(controller.results['对角线'], '1.414214');
    });

    test('切换几何体后输入单位重置为 m', () {
      controller.setInputUnit('r', 'cm');
      controller.setShape(GeometryShape.rectangle);
      expect(controller.inputUnit('a'), 'm');
      expect(controller.inputUnit('b'), 'm');
    });

    test('不同输出结果可单独设置输出单位', () {
      controller.setShape(GeometryShape.cylinder);
      controller.setInput('r', '1');
      controller.setInput('h', '1');
      // 圆柱默认：体积 m³, 侧面积 m², 表面积 m²
      expect(controller.results['体积'], '3.141593');
      expect(controller.results['侧面积'], '6.283185');

      controller.setOutputUnit('体积', 'L');
      controller.setOutputUnit('侧面积', 'cm²');
      expect(controller.results['体积'], '3141.592654');
      expect(controller.results['侧面积'], '62831.853072');
      expect(controller.results['表面积'], '12.566371');
    });

    test('切换几何体后输出单位重置', () {
      controller.setInput('r', '1');
      controller.setOutputUnit('面积', 'km²');
      controller.setShape(GeometryShape.cuboid);
      expect(controller.outputUnit('体积'), 'm³');
      expect(controller.outputUnit('表面积'), 'm²');
    });
  });
}
