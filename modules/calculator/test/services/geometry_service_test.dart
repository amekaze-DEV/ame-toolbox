import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:calculator_module/features/calculator/models/geometry_shape.dart';
import 'package:calculator_module/features/calculator/services/geometry_service.dart';

void main() {
  group('GeometryService', () {
    late GeometryService service;

    setUp(() {
      service = GeometryService();
    });

    group('GeometryShape displayName', () {
      test('各几何体显示名称正确', () {
        expect(GeometryShape.circle.displayName, '圆');
        expect(GeometryShape.rectangle.displayName, '矩形');
        expect(GeometryShape.cuboid.displayName, '长方体');
        expect(GeometryShape.cylinder.displayName, '圆柱');
        expect(GeometryShape.cone.displayName, '圆锥');
        expect(GeometryShape.sphere.displayName, '球');
        expect(GeometryShape.hollowCylinder.displayName, '圆筒');
        expect(GeometryShape.pyramid.displayName, '棱锥');
      });
    });

    group('GeometryResult', () {
      test('error 构造返回 isError=true', () {
        final result = GeometryResult.error('测试错误');
        expect(result.isError, true);
        expect(result.error, '测试错误');
        expect(result.results, isEmpty);
      });
    });

    group('getInputFields', () {
      test('圆需要 r', () {
        expect(service.getInputFields(GeometryShape.circle), ['r']);
      });

      test('长方体需要 a, b, h', () {
        expect(
          service.getInputFields(GeometryShape.cuboid),
          ['a', 'b', 'h'],
        );
      });

      test('圆锥需要 r, h, l 三个字段（任意两个有值即可计算）', () {
        expect(service.getInputFields(GeometryShape.cone), ['r', 'h', 'l']);
      });
    });

    group('getFormulaDescription', () {
      test('圆公式说明', () {
        expect(
          service.getFormulaDescription(GeometryShape.circle),
          '面积 = πr²；周长 = 2πr',
        );
      });

      test('棱锥公式说明包含底面积与侧面积', () {
        final desc = service.getFormulaDescription(GeometryShape.pyramid);
        expect(desc, contains('底面积'));
        expect(desc, contains('侧面积'));
        expect(desc, contains('tan'));
      });
    });

    group('圆', () {
      test('r=1 时面积=π、周长=2π', () {
        final result = service.calculate(GeometryShape.circle, {'r': 1});
        expect(result.isError, false);
        expect(result.results['面积'], closeTo(math.pi, 1e-10));
        expect(result.results['周长'], closeTo(2 * math.pi, 1e-10));
      });

      test('r=2 时面积=4π、周长=4π', () {
        final result = service.calculate(GeometryShape.circle, {'r': 2});
        expect(result.results['面积'], closeTo(4 * math.pi, 1e-10));
        expect(result.results['周长'], closeTo(4 * math.pi, 1e-10));
      });

      test('r<=0 校验失败', () {
        final result = service.calculate(GeometryShape.circle, {'r': 0});
        expect(result.isError, true);
        expect(result.error, '所有尺寸必须大于 0');
      });
    });

    group('矩形', () {
      test('a=3, b=4 时面积=12、周长=14、对角线=5', () {
        final result = service.calculate(GeometryShape.rectangle, {
          'a': 3,
          'b': 4,
        });
        expect(result.isError, false);
        expect(result.results['面积'], 12);
        expect(result.results['周长'], 14);
        expect(result.results['对角线'], 5);
      });
    });

    group('长方体', () {
      test('a=2, b=3, h=4 时体积=24、表面积=52', () {
        final result = service.calculate(GeometryShape.cuboid, {
          'a': 2,
          'b': 3,
          'h': 4,
        });
        expect(result.isError, false);
        expect(result.results['体积'], 24);
        expect(result.results['表面积'], 52);
      });
    });

    group('圆柱', () {
      test('r=1, h=2 时体积=2π、侧面积=4π、表面积=6π', () {
        final result = service.calculate(GeometryShape.cylinder, {
          'r': 1,
          'h': 2,
        });
        expect(result.isError, false);
        expect(result.results['体积'], closeTo(2 * math.pi, 1e-10));
        expect(result.results['侧面积'], closeTo(4 * math.pi, 1e-10));
        expect(result.results['表面积'], closeTo(6 * math.pi, 1e-10));
      });
    });

    group('圆锥', () {
      test('r=3, h=4 时自动计算 l=5', () {
        final result = service.calculate(GeometryShape.cone, {
          'r': 3,
          'h': 4,
        });
        expect(result.isError, false);
        expect(result.results['体积'], closeTo(12 * math.pi, 1e-10));
        expect(result.results['侧面积'], closeTo(15 * math.pi, 1e-10));
        expect(result.results['表面积'], closeTo(24 * math.pi, 1e-10));
      });

      test('r=3, l=5 时自动计算 h=4', () {
        final result = service.calculate(GeometryShape.cone, {
          'r': 3,
          'l': 5,
        });
        expect(result.isError, false);
        expect(result.results['体积'], closeTo(12 * math.pi, 1e-10));
        expect(result.results['侧面积'], closeTo(15 * math.pi, 1e-10));
      });

      test('h=4, l=5 时自动计算 r=3', () {
        final result = service.calculate(GeometryShape.cone, {
          'h': 4,
          'l': 5,
        });
        expect(result.isError, false);
        expect(result.results['体积'], closeTo(12 * math.pi, 1e-10));
        expect(result.results['侧面积'], closeTo(15 * math.pi, 1e-10));
      });

      test('r=3, h=4, l=5 时校验通过', () {
        final result = service.calculate(GeometryShape.cone, {
          'r': 3,
          'h': 4,
          'l': 5,
        });
        expect(result.isError, false);
        expect(result.results['侧面积'], closeTo(15 * math.pi, 1e-10));
      });

      test('r=3, h=4, l=6 时校验失败', () {
        final result = service.calculate(GeometryShape.cone, {
          'r': 3,
          'h': 4,
          'l': 6,
        });
        expect(result.isError, true);
        expect(result.error, contains('母线长 l 必须满足'));
      });

      test('只提供一个参数时报错', () {
        final result = service.calculate(GeometryShape.cone, {'r': 3});
        expect(result.isError, true);
        expect(result.error, contains('任意两个'));
      });
    });

    group('球', () {
      test('r=1 时体积=(4/3)π、表面积=4π', () {
        final result = service.calculate(GeometryShape.sphere, {'r': 1});
        expect(result.isError, false);
        expect(result.results['体积'], closeTo((4 / 3) * math.pi, 1e-10));
        expect(result.results['表面积'], closeTo(4 * math.pi, 1e-10));
      });
    });

    group('圆筒', () {
      test('R=3, r=2, h=5 时体积=25π、表面积=60π', () {
        final result = service.calculate(GeometryShape.hollowCylinder, {
          'R': 3,
          'r': 2,
          'h': 5,
        });
        expect(result.isError, false);
        expect(result.results['体积'], closeTo(25 * math.pi, 1e-10));
        expect(result.results['表面积'], closeTo(60 * math.pi, 1e-10));
      });

      test('R=r 时校验失败', () {
        final result = service.calculate(GeometryShape.hollowCylinder, {
          'R': 2,
          'r': 2,
          'h': 5,
        });
        expect(result.isError, true);
        expect(result.error, '圆筒外径 R 必须大于内径 r');
      });

      test('R<r 时校验失败', () {
        final result = service.calculate(GeometryShape.hollowCylinder, {
          'R': 1,
          'r': 2,
          'h': 5,
        });
        expect(result.isError, true);
        expect(result.error, '圆筒外径 R 必须大于内径 r');
      });
    });

    group('棱锥', () {
      test('n=4, a=2, h=3 计算正常', () {
        final result = service.calculate(GeometryShape.pyramid, {
          'n': 4,
          'a': 2,
          'h': 3,
        });
        expect(result.isError, false);
        expect(result.results.containsKey('底面积'), true);
        expect(result.results.containsKey('体积'), true);
        expect(result.results.containsKey('侧面积'), true);
        expect(result.results.containsKey('表面积'), true);
      });

      test('n=3 时计算正常', () {
        final result = service.calculate(GeometryShape.pyramid, {
          'n': 3,
          'a': 2,
          'h': 3,
        });
        expect(result.isError, false);
      });

      test('n=2 时校验失败', () {
        final result = service.calculate(GeometryShape.pyramid, {
          'n': 2,
          'a': 2,
          'h': 3,
        });
        expect(result.isError, true);
        expect(result.error, '棱锥底边数 n 必须大于等于 3 且为整数');
      });

      test('n 非整数时校验失败', () {
        final result = service.calculate(GeometryShape.pyramid, {
          'n': 3.5,
          'a': 2,
          'h': 3,
        });
        expect(result.isError, true);
        expect(result.error, '棱锥底边数 n 必须大于等于 3 且为整数');
      });
    });

    group('通用校验', () {
      test('缺少必填字段时报错', () {
        final result = service.calculate(GeometryShape.circle, {});
        expect(result.isError, true);
        expect(result.error, '所有尺寸必须大于 0');
      });

      test('负数尺寸校验失败', () {
        final result = service.calculate(GeometryShape.rectangle, {
          'a': -1,
          'b': 4,
        });
        expect(result.isError, true);
        expect(result.error, '所有尺寸必须大于 0');
      });
    });
  });
}
