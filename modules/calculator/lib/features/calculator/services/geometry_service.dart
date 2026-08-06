import 'dart:math' as math;

import 'package:calculator_module/features/calculator/models/geometry_shape.dart';

/// 几何公式库业务服务。
///
/// 负责 8 种几何体的面积、周长、体积、表面积计算及输入校验。
class GeometryService {
  static const String _errorInvalidInput = '输入参数无效';
  static const String _errorDimensionMustBePositive = '所有尺寸必须大于 0';
  static const String _errorHollowCylinderRadius = '圆筒外径 R 必须大于内径 r';
  static const String _errorPyramidSides = '棱锥底边数 n 必须大于等于 3 且为整数';

  /// 返回指定几何体所需的参数字段列表。
  ///
  /// 字段名与 [calculate] 方法 [inputs] 的键名一致；圆锥的 `l` 为可选字段。
  List<String> getInputFields(GeometryShape shape) {
    switch (shape) {
      case GeometryShape.circle:
        return const ['r'];
      case GeometryShape.rectangle:
        return const ['a', 'b'];
      case GeometryShape.cuboid:
        return const ['a', 'b', 'h'];
      case GeometryShape.cylinder:
        return const ['r', 'h'];
      case GeometryShape.cone:
        return const ['r', 'h', 'l'];
      case GeometryShape.sphere:
        return const ['r'];
      case GeometryShape.hollowCylinder:
        return const ['R', 'r', 'h'];
      case GeometryShape.pyramid:
        return const ['n', 'a', 'h'];
    }
  }

  /// 返回参数字段的中文注释，用于输入框标签。
  ///
  /// 同一字段在不同几何体中含义相同：
  /// - `r`：半径；`R`：外径；`a`：边长/长；`b`：边长/宽；`h`：高；`l`：母线；`n`：边数。
  String getInputLabel(String field, {bool isOptional = false}) {
    final label = switch (field) {
      'r' => '半径 r',
      'R' => '外径 R',
      'a' => '边长 a',
      'b' => '边长 b',
      'h' => '高 h',
      'l' => '母线 l',
      'n' => '边数 n',
      _ => field,
    };
    return isOptional ? '$label（可选）' : label;
  }

  /// 返回指定几何体的公式说明文本。
  String getFormulaDescription(GeometryShape shape) {
    switch (shape) {
      case GeometryShape.circle:
        return '面积 = πr²；周长 = 2πr';
      case GeometryShape.rectangle:
        return '面积 = ab；周长 = 2(a+b)；对角线 = √(a²+b²)';
      case GeometryShape.cuboid:
        return '体积 = abh；表面积 = 2(ab+ah+bh)';
      case GeometryShape.cylinder:
        return '体积 = πr²h；侧面积 = 2πrh；表面积 = 2πr(r+h)';
      case GeometryShape.cone:
        return 'r、h、l 中任意两个可推出第三个（l² = r² + h²）；体积 = (1/3)πr²h；侧面积 = πrl；表面积 = πr(r+l)';
      case GeometryShape.sphere:
        return '体积 = (4/3)πr³；表面积 = 4πr²';
      case GeometryShape.hollowCylinder:
        return '体积 = π(R²-r²)h；表面积 = 2πRh + 2πrh + 2π(R²-r²)';
      case GeometryShape.pyramid:
        return '底面积 = (n a²)/(4 tan(π/n))；体积 = (1/3) × 底面积 × h；'
            '侧面积 = (n a s)/2，s = √(h² + (a/(2 tan(π/n)))²)；表面积 = 底面积 + 侧面积';
    }
  }

  /// 计算指定几何体的所有可计算量。
  ///
  /// [inputs] 的键名需与 [getInputFields] 返回的字段名一致。
  /// 校验失败时返回包含 [GeometryResult.error] 的结果。
  GeometryResult calculate(GeometryShape shape, Map<String, double> inputs) {
    try {
      switch (shape) {
        case GeometryShape.circle:
          return _calculateCircle(inputs);
        case GeometryShape.rectangle:
          return _calculateRectangle(inputs);
        case GeometryShape.cuboid:
          return _calculateCuboid(inputs);
        case GeometryShape.cylinder:
          return _calculateCylinder(inputs);
        case GeometryShape.cone:
          return _calculateCone(inputs);
        case GeometryShape.sphere:
          return _calculateSphere(inputs);
        case GeometryShape.hollowCylinder:
          return _calculateHollowCylinder(inputs);
        case GeometryShape.pyramid:
          return _calculatePyramid(inputs);
      }
    } on ArgumentError catch (e) {
      return GeometryResult.error(e.message?.toString() ?? _errorInvalidInput);
    }
  }

  GeometryResult _calculateCircle(Map<String, double> inputs) {
    _requirePositive(inputs, const ['r']);
    final r = inputs['r']!;
    return GeometryResult(results: {
      '面积': math.pi * r * r,
      '周长': 2 * math.pi * r,
    });
  }

  GeometryResult _calculateRectangle(Map<String, double> inputs) {
    _requirePositive(inputs, const ['a', 'b']);
    final a = inputs['a']!;
    final b = inputs['b']!;
    return GeometryResult(results: {
      '面积': a * b,
      '周长': 2 * (a + b),
      '对角线': math.sqrt(a * a + b * b),
    });
  }

  GeometryResult _calculateCuboid(Map<String, double> inputs) {
    _requirePositive(inputs, const ['a', 'b', 'h']);
    final a = inputs['a']!;
    final b = inputs['b']!;
    final h = inputs['h']!;
    return GeometryResult(results: {
      '体积': a * b * h,
      '表面积': 2 * (a * b + a * h + b * h),
    });
  }

  GeometryResult _calculateCylinder(Map<String, double> inputs) {
    _requirePositive(inputs, const ['r', 'h']);
    final r = inputs['r']!;
    final h = inputs['h']!;
    final lateralArea = 2 * math.pi * r * h;
    return GeometryResult(results: {
      '体积': math.pi * r * r * h,
      '侧面积': lateralArea,
      '表面积': 2 * math.pi * r * (r + h),
    });
  }

  GeometryResult _calculateCone(Map<String, double> inputs) {
    final rRaw = inputs['r'];
    final hRaw = inputs['h'];
    final lRaw = inputs['l'];

    // 必须提供三个参数中的至少两个。
    final providedCount = [rRaw, hRaw, lRaw].whereType<double>().length;
    if (providedCount < 2) {
      throw ArgumentError('圆锥需要 r、h、l 中的任意两个参数');
    }

    // 所有提供的参数必须大于 0。
    for (final value in [rRaw, hRaw, lRaw].whereType<double>()) {
      if (value <= 0) {
        throw ArgumentError(_errorDimensionMustBePositive);
      }
    }

    late final double r;
    late final double h;
    late final double l;

    if (rRaw != null && hRaw != null && lRaw != null) {
      // 三个都提供时校验勾股定理一致性（允许 1e-9 浮点误差）。
      final expectedL = math.sqrt(rRaw * rRaw + hRaw * hRaw);
      if ((lRaw - expectedL).abs() > 1e-9) {
        throw ArgumentError('母线长 l 必须满足 l² = r² + h²');
      }
      r = rRaw;
      h = hRaw;
      l = lRaw;
    } else if (rRaw != null && hRaw != null) {
      r = rRaw;
      h = hRaw;
      l = math.sqrt(r * r + h * h);
    } else if (rRaw != null && lRaw != null) {
      if (lRaw <= rRaw) {
        throw ArgumentError('母线长 l 必须大于底半径 r');
      }
      r = rRaw;
      l = lRaw;
      h = math.sqrt(l * l - r * r);
    } else if (hRaw != null && lRaw != null) {
      if (lRaw <= hRaw) {
        throw ArgumentError('母线长 l 必须大于高 h');
      }
      h = hRaw;
      l = lRaw;
      r = math.sqrt(l * l - h * h);
    } else {
      // providedCount >= 2 已保证不会进入此分支。
      throw ArgumentError(_errorInvalidInput);
    }

    return GeometryResult(results: {
      '体积': (1 / 3) * math.pi * r * r * h,
      '侧面积': math.pi * r * l,
      '表面积': math.pi * r * (r + l),
    });
  }

  GeometryResult _calculateSphere(Map<String, double> inputs) {
    _requirePositive(inputs, const ['r']);
    final r = inputs['r']!;
    return GeometryResult(results: {
      '体积': (4 / 3) * math.pi * r * r * r,
      '表面积': 4 * math.pi * r * r,
    });
  }

  GeometryResult _calculateHollowCylinder(Map<String, double> inputs) {
    _requirePositive(inputs, const ['R', 'r', 'h']);
    final R = inputs['R']!;
    final r = inputs['r']!;
    final h = inputs['h']!;
    if (R <= r) {
      throw ArgumentError(_errorHollowCylinderRadius);
    }
    final annularArea = math.pi * (R * R - r * r);
    return GeometryResult(results: {
      '体积': annularArea * h,
      '表面积': 2 * math.pi * R * h + 2 * math.pi * r * h + 2 * annularArea,
    });
  }

  GeometryResult _calculatePyramid(Map<String, double> inputs) {
    _requirePositive(inputs, const ['a', 'h']);
    final n = inputs['n'];
    if (n == null || n < 3 || n != n.truncateToDouble()) {
      throw ArgumentError(_errorPyramidSides);
    }
    final nInt = n.toInt();
    final a = inputs['a']!;
    final h = inputs['h']!;
    final apothemFactor = a / (2 * math.tan(math.pi / nInt));
    final baseArea = (nInt * a * a) / (4 * math.tan(math.pi / nInt));
    final slantHeight = math.sqrt(h * h + apothemFactor * apothemFactor);
    final lateralArea = (nInt * a * slantHeight) / 2;
    return GeometryResult(results: {
      '底面积': baseArea,
      '体积': (1 / 3) * baseArea * h,
      '侧面积': lateralArea,
      '表面积': baseArea + lateralArea,
    });
  }

  /// 校验 [inputs] 中指定的字段均存在且大于 0。
  void _requirePositive(Map<String, double> inputs, List<String> keys) {
    for (final key in keys) {
      final value = inputs[key];
      if (value == null || value <= 0) {
        throw ArgumentError(_errorDimensionMustBePositive);
      }
    }
  }
}
