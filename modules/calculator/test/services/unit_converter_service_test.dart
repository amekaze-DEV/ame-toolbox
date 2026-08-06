import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:calculator_module/features/calculator/models/unit_category.dart';
import 'package:calculator_module/features/calculator/services/unit_converter_service.dart';

void main() {
  group('UnitConverterService', () {
    late UnitConverterService service;

    setUp(() {
      service = UnitConverterService();
    });

    group('长度', () {
      test('1000 m 等于 1 km', () {
        final result = service.convert(
            UnitCategory.length, 'm', 'km', 1000);
        expect(result, closeTo(1, 1e-9));
      });

      test('1 mi 约为 1609.344 m', () {
        final result = service.convert(
            UnitCategory.length, 'mi', 'm', 1);
        expect(result, closeTo(1609.344, 1e-6));
      });

      test('1 ft 约为 30.48 cm', () {
        final result = service.convert(
            UnitCategory.length, 'ft', 'cm', 1);
        expect(result, closeTo(30.48, 1e-6));
      });
    });

    group('重量', () {
      test('1 kg 约为 2.20462 lb', () {
        final result = service.convert(
            UnitCategory.weight, 'kg', 'lb', 1);
        expect(result, closeTo(2.20462, 1e-5));
      });

      test('1 t 等于 1000 kg', () {
        final result = service.convert(
            UnitCategory.weight, 't', 'kg', 1);
        expect(result, closeTo(1000, 1e-9));
      });

      test('1 st 约为 6350.29 g', () {
        final result = service.convert(
            UnitCategory.weight, 'st', 'g', 1);
        expect(result, closeTo(6350.29318, 1e-5));
      });
    });

    group('温度', () {
      test('0 °C 等于 32 °F', () {
        final result = service.convert(
            UnitCategory.temperature, '°C', '°F', 0);
        expect(result, closeTo(32, 1e-9));
      });

      test('100 °C 等于 212 °F', () {
        final result = service.convert(
            UnitCategory.temperature, '°C', '°F', 100);
        expect(result, closeTo(212, 1e-9));
      });

      test('-40 °C 等于 -40 °F', () {
        final result = service.convert(
            UnitCategory.temperature, '°C', '°F', -40);
        expect(result, closeTo(-40, 1e-9));
      });

      test('0 °C 等于 273.15 K', () {
        final result = service.convert(
            UnitCategory.temperature, '°C', 'K', 0);
        expect(result, closeTo(273.15, 1e-9));
      });

      test('273.15 K 等于 32 °F', () {
        final result = service.convert(
            UnitCategory.temperature, 'K', '°F', 273.15);
        expect(result, closeTo(32, 1e-9));
      });

      test('100 °F 约为 310.928 K', () {
        final result = service.convert(
            UnitCategory.temperature, '°F', 'K', 100);
        expect(result, closeTo(310.9277778, 1e-4));
      });
    });

    group('面积', () {
      test('1 ha 等于 10000 m²', () {
        final result = service.convert(
            UnitCategory.area, 'ha', 'm²', 1);
        expect(result, closeTo(10000, 1e-9));
      });

      test('1 km² 约为 247.105 ac', () {
        final result = service.convert(
            UnitCategory.area, 'km²', 'ac', 1);
        expect(result, closeTo(247.105, 1e-3));
      });

      test('1 ft² 约为 929.030 cm²', () {
        final result = service.convert(
            UnitCategory.area, 'ft²', 'cm²', 1);
        expect(result, closeTo(929.0304, 1e-4));
      });
    });

    group('体积', () {
      test('1 L 等于 1000 mL', () {
        final result = service.convert(
            UnitCategory.volume, 'L', 'mL', 1);
        expect(result, closeTo(1000, 1e-9));
      });

      test('1 gal(US) 约为 3.78541 L', () {
        final result = service.convert(
            UnitCategory.volume, 'gal(US)', 'L', 1);
        expect(result, closeTo(3.785411784, 1e-6));
      });

      test('1 m³ 约为 35.3147 ft³', () {
        final result = service.convert(
            UnitCategory.volume, 'm³', 'ft³', 1);
        expect(result, closeTo(35.31466672, 1e-5));
      });
    });

    group('速度', () {
      test('36 km/h 等于 10 m/s', () {
        final result = service.convert(
            UnitCategory.speed, 'km/h', 'm/s', 36);
        expect(result, closeTo(10, 1e-9));
      });

      test('1 mph 约为 1.60934 km/h', () {
        final result = service.convert(
            UnitCategory.speed, 'mph', 'km/h', 1);
        expect(result, closeTo(1.609344, 1e-6));
      });

      test('1 kn 约为 1.852 km/h', () {
        final result = service.convert(
            UnitCategory.speed, 'kn', 'km/h', 1);
        expect(result, closeTo(1.852, 1e-6));
      });
    });

    group('时间', () {
      test('1 h 等于 60 min', () {
        final result = service.convert(
            UnitCategory.time, 'h', 'min', 1);
        expect(result, closeTo(60, 1e-9));
      });

      test('1 d 等于 24 h', () {
        final result = service.convert(
            UnitCategory.time, 'd', 'h', 1);
        expect(result, closeTo(24, 1e-9));
      });

      test('12 mo 等于 1 y', () {
        final result = service.convert(
            UnitCategory.time, 'mo', 'y', 12);
        expect(result, closeTo(1, 1e-9));
      });
    });

    group('角度', () {
      test('180 deg 等于 pi rad', () {
        final result = service.convert(
            UnitCategory.angle, 'deg', 'rad', 180);
        expect(result, closeTo(math.pi, 1e-9));
      });

      test('100 grad 等于 90 deg', () {
        final result = service.convert(
            UnitCategory.angle, 'grad', 'deg', 100);
        expect(result, closeTo(90, 1e-9));
      });

      test('1 rad 约为 63.662 grad', () {
        final result = service.convert(
            UnitCategory.angle, 'rad', 'grad', 1);
        expect(result, closeTo(63.66197724, 1e-5));
      });
    });

    group('getUnits', () {
      test('温度单位列表', () {
        final units = service.getUnits(UnitCategory.temperature);
        expect(units, equals(const ['°C', '°F', 'K']));
      });

      test('时间单位列表包含 mo', () {
        final units = service.getUnits(UnitCategory.time);
        expect(units, contains('mo'));
        expect(units.length, 8);
      });

      test('角度单位列表包含 grad', () {
        final units = service.getUnits(UnitCategory.angle);
        expect(units, contains('grad'));
        expect(units.length, 3);
      });
    });

    group('错误处理', () {
      test('无效源单位抛出 FormatException', () {
        expect(
          () => service.convert(
              UnitCategory.length, 'xxx', 'm', 1),
          throwsA(isA<FormatException>().having(
              (e) => e.message, 'message', contains('无效的单位'))),
        );
      });

      test('无效目标单位抛出 FormatException', () {
        expect(
          () => service.convert(
              UnitCategory.weight, 'kg', 'xxx', 1),
          throwsA(isA<FormatException>().having(
              (e) => e.message, 'message', contains('无效的单位'))),
        );
      });

      test('空字符串单位视为无效', () {
        expect(
          () => service.convert(
              UnitCategory.area, '', 'm²', 1),
          throwsA(isA<FormatException>()),
        );
      });

      test('无效温度单位抛出 FormatException', () {
        expect(
          () => service.convert(
              UnitCategory.temperature, '°C', 'xxx', 0),
          throwsA(isA<FormatException>().having(
              (e) => e.message, 'message', contains('无效的温度单位'))),
        );
      });

      test('相同单位返回原值', () {
        final result = service.convert(
            UnitCategory.length, 'm', 'm', 42);
        expect(result, 42);
      });
    });

    group('结果格式化', () {
      test('默认精度去除末尾 0', () {
        final formatted = service.formatResult(2.0, precision: 6);
        expect(formatted, '2');
      });

      test('极小值自动转科学计数法', () {
        final formatted = service.formatResult(1e-12, precision: 6);
        expect(formatted, contains('E-'));
      });

      test('NaN 显示 Error', () {
        final formatted = service.formatResult(double.nan);
        expect(formatted, 'Error');
      });
    });
  });
}
