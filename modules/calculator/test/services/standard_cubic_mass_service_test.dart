import 'package:flutter_test/flutter_test.dart';
import 'package:calculator_module/features/calculator/models/gas_type.dart';
import 'package:calculator_module/features/calculator/services/standard_cubic_mass_service.dart';

void main() {
  group('StandardCubicMassService', () {
    const service = StandardCubicMassService();
    const vm = StandardCubicMassService.defaultStandardMolarVolume;

    group('calculateMass', () {
      test('甲烷 1 Nm³ → 约 0.716 kg', () {
        final result = service.calculateMass(1, 'Nm³', 16.04, vm);
        expect(result, closeTo(0.716, 0.001));
      });

      test('氧气 1 m³ → 约 1.428 kg', () {
        final result = service.calculateMass(1, 'm³', 31.998, vm);
        expect(result, closeTo(1.428, 0.001));
      });

      test('丙烷 1000 L → 约 1.967 kg', () {
        final result = service.calculateMass(1000, 'L', 44.10, vm);
        expect(result, closeTo(1.967, 0.001));
      });

      test('零体积返回 0', () {
        final result = service.calculateMass(0, 'Nm³', 16.04, vm);
        expect(result, 0);
      });
    });

    group('calculateVolume', () {
      test('空气 1 kg → 约 0.773 Nm³', () {
        final result = service.calculateVolume(1, 'kg', 28.97, vm);
        expect(result, closeTo(0.773, 0.001));
      });

      test('氮气 1.25 kg → 约 1 Nm³', () {
        final result = service.calculateVolume(1.25, 'kg', 28.013, vm);
        expect(result, closeTo(1, 0.01));
      });

      test('零质量返回 0', () {
        final result = service.calculateVolume(0, 'kg', 28.97, vm);
        expect(result, 0);
      });
    });

    group('convertVolumeToNm3', () {
      test('Nm³ 不变', () {
        expect(service.convertVolumeToNm3(5, 'Nm³'), 5);
      });

      test('m³ 与 Nm³ 系数相同', () {
        expect(service.convertVolumeToNm3(2, 'm³'), 2);
      });

      test('L → Nm³', () {
        expect(service.convertVolumeToNm3(1000, 'L'), 1);
      });
    });

    group('convertMassToKg', () {
      test('kg 不变', () {
        expect(service.convertMassToKg(3, 'kg'), 3);
      });

      test('g → kg', () {
        expect(service.convertMassToKg(500, 'g'), 0.5);
      });

      test('t → kg', () {
        expect(service.convertMassToKg(2, 't'), 2000);
      });

      test('lb → kg', () {
        expect(service.convertMassToKg(1, 'lb'), closeTo(0.45359237, 1e-9));
      });

      test('oz → kg', () {
        expect(service.convertMassToKg(1, 'oz'), closeTo(0.0283495231, 1e-9));
      });
    });

    group('calculateDensity', () {
      test('甲烷标准密度约 0.716 kg/Nm³', () {
        final result = service.calculateDensity(16.04, vm);
        expect(result, closeTo(0.716, 0.001));
      });

      test('空气标准密度约 1.293 kg/Nm³', () {
        final result = service.calculateDensity(28.97, vm);
        expect(result, closeTo(1.293, 0.001));
      });
    });

    group('resolveMolarMass', () {
      test('内置气体返回固定摩尔质量', () {
        expect(service.resolveMolarMass(GasType.naturalGas), 16.04);
        expect(service.resolveMolarMass(GasType.air), 28.97);
        expect(service.resolveMolarMass(GasType.oxygen), 31.998);
        expect(service.resolveMolarMass(GasType.nitrogen), 28.013);
        expect(service.resolveMolarMass(GasType.hydrogen), 2.016);
        expect(service.resolveMolarMass(GasType.carbonDioxide), 44.01);
        expect(service.resolveMolarMass(GasType.propane), 44.10);
      });

      test('自定义气体返回 null', () {
        expect(service.resolveMolarMass(GasType.custom), isNull);
      });
    });

    group('GasTypeExtension', () {
      test('displayName 正确', () {
        expect(GasType.naturalGas.displayName, '天然气（甲烷）');
        expect(GasType.custom.displayName, '自定义');
      });

      test('fromString 正确还原', () {
        expect(GasTypeExtension.fromString('oxygen'), GasType.oxygen);
        expect(GasTypeExtension.fromString('unknown'), GasType.custom);
      });
    });

    group('校验异常', () {
      test('摩尔质量 <= 0 抛出 ArgumentError', () {
        expect(
          () => service.calculateMass(1, 'Nm³', 0, vm),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => service.calculateMass(1, 'Nm³', -1, vm),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('标准摩尔体积 <= 0 抛出 ArgumentError', () {
        expect(
          () => service.calculateMass(1, 'Nm³', 16.04, 0),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => service.calculateDensity(16.04, -vm),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('负体积抛出 ArgumentError', () {
        expect(
          () => service.calculateMass(-1, 'Nm³', 16.04, vm),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('负质量抛出 ArgumentError', () {
        expect(
          () => service.calculateVolume(-1, 'kg', 28.97, vm),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('未知体积单位抛出 ArgumentError', () {
        expect(
          () => service.calculateMass(1, 'ft³', 16.04, vm),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('未知质量单位抛出 ArgumentError', () {
        expect(
          () => service.calculateVolume(1, 'mg', 28.97, vm),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
