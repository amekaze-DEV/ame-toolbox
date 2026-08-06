import 'dart:math' as math;

import 'package:units_converter/models/double_property.dart';
import 'package:units_converter/units_converter.dart';

import 'package:calculator_module/features/calculator/models/unit_category.dart';

/// 单位转换服务。
///
/// 封装 `units_converter` 并提供温度自研公式转换。
/// 除温度外，其他类别优先使用 `units_converter` 完成线性换算；
/// 时间和角度因规格单位（mo、grad）不在 `units_converter` 默认单位内，
/// 使用 `SimpleCustomProperty` 自定义线性换算。
class UnitConverterService {
  static const String _errorInvalidUnit = '无效的单位';
  static const String _errorInvalidTemperatureUnit = '无效的温度单位';

  // ----- 长度：符号 -> LENGTH 枚举 -----
  static final Map<String, LENGTH> _lengthUnits = {
    'mm': LENGTH.millimeters,
    'cm': LENGTH.centimeters,
    'm': LENGTH.meters,
    'km': LENGTH.kilometers,
    'in': LENGTH.inches,
    'ft': LENGTH.feet,
    'yd': LENGTH.yards,
    'mi': LENGTH.miles,
  };

  // ----- 重量：符号 -> MASS 枚举 -----
  static final Map<String, MASS> _weightUnits = {
    'mg': MASS.milligrams,
    'g': MASS.grams,
    'kg': MASS.kilograms,
    't': MASS.tonnes,
    'oz': MASS.ounces,
    'lb': MASS.pounds,
    'st': MASS.stones,
  };

  // ----- 面积：符号 -> AREA 枚举 -----
  static final Map<String, AREA> _areaUnits = {
    'mm²': AREA.squareMillimeters,
    'cm²': AREA.squareCentimeters,
    'm²': AREA.squareMeters,
    'ha': AREA.hectares,
    'km²': AREA.squareKilometers,
    'in²': AREA.squareInches,
    'ft²': AREA.squareFeet,
    'ac': AREA.acres,
  };

  // ----- 体积：符号 -> VOLUME 枚举 -----
  static final Map<String, VOLUME> _volumeUnits = {
    'mL': VOLUME.milliliters,
    'L': VOLUME.liters,
    'm³': VOLUME.cubicMeters,
    'cm³': VOLUME.cubicCentimeters,
    'ft³': VOLUME.cubicFeet,
    'gal(US)': VOLUME.usGallons,
    'pt(US)': VOLUME.usPints,
  };

  // ----- 速度：符号 -> SPEED 枚举 -----
  static final Map<String, SPEED> _speedUnits = {
    'm/s': SPEED.metersPerSecond,
    'km/h': SPEED.kilometersPerHour,
    'mph': SPEED.milesPerHour,
    'kn': SPEED.knots,
    'ft/s': SPEED.feetsPerSecond,
  };

  // ----- 时间：自研线性换算，基准为 s -----
  static const Map<String, double> _timeFactors = {
    'ms': 1e-3,
    's': 1,
    'min': 60,
    'h': 3600,
    'd': 86400,
    'wk': 604800,
    'mo': 2628000, // 365 / 12 天
    'y': 31536000, // 365 天
  };

  // ----- 角度：自研线性换算，基准为 deg -----
  static final Map<String, double> _angleFactors = {
    'deg': 1,
    'rad': 180 / math.pi,
    'grad': 0.9, // 1 grad = 0.9 deg
  };

  /// 返回指定类别支持的所有单位符号。
  List<String> getUnits(UnitCategory category) => category.units;

  /// 执行单位换算。
  ///
  /// - [category]：单位类别。
  /// - [fromUnit]：源单位符号。
  /// - [toUnit]：目标单位符号。
  /// - [value]：待换算的数值。
  ///
  /// 当源或目标单位无效时，抛出 [FormatException] 并附带中文错误信息。
  double convert(
    UnitCategory category,
    String fromUnit,
    String toUnit,
    double value,
  ) {
    if (category == UnitCategory.temperature) {
      return _convertTemperature(fromUnit, toUnit, value);
    }

    if (fromUnit == toUnit) return value;

    switch (category) {
      case UnitCategory.length:
        return _convertWithProperty(
            Length(), _lengthUnits, fromUnit, toUnit, value);
      case UnitCategory.weight:
        return _convertWithProperty(
            Mass(), _weightUnits, fromUnit, toUnit, value);
      case UnitCategory.area:
        return _convertWithProperty(
            Area(), _areaUnits, fromUnit, toUnit, value);
      case UnitCategory.volume:
        return _convertWithProperty(
            Volume(), _volumeUnits, fromUnit, toUnit, value);
      case UnitCategory.speed:
        return _convertWithProperty(
            Speed(), _speedUnits, fromUnit, toUnit, value);
      case UnitCategory.time:
        return _convertWithFactors(
            _timeFactors, fromUnit, toUnit, value);
      case UnitCategory.angle:
        return _convertWithFactors(
            _angleFactors, fromUnit, toUnit, value);
      case UnitCategory.temperature:
        // 已在前面处理，此处不可达。
        throw FormatException(_errorInvalidTemperatureUnit);
    }
  }

  /// 使用 `units_converter` 的 [DoubleProperty] 进行线性换算。
  static double _convertWithProperty<T>(
    DoubleProperty<T> property,
    Map<String, T> unitMap,
    String fromUnit,
    String toUnit,
    double value,
  ) {
    final from = unitMap[fromUnit];
    final to = unitMap[toUnit];
    if (from == null || to == null) {
      throw FormatException('$_errorInvalidUnit：$fromUnit → $toUnit');
    }

    property.convert(from, value);
    return property.getUnit(to).value ?? double.nan;
  }

  /// 使用自定义换算系数进行线性换算。
  static double _convertWithFactors(
    Map<String, double> factors,
    String fromUnit,
    String toUnit,
    double value,
  ) {
    final fromFactor = factors[fromUnit];
    final toFactor = factors[toUnit];
    if (fromFactor == null || toFactor == null) {
      throw FormatException('$_errorInvalidUnit：$fromUnit → $toUnit');
    }

    return value * fromFactor / toFactor;
  }

  /// 温度换算，使用自研公式，不经过线性换算。
  static double _convertTemperature(
      String fromUnit, String toUnit, double value) {
    if (fromUnit == toUnit) return value;

    final double celsius;
    switch (fromUnit) {
      case '°C':
        celsius = value;
      case '°F':
        celsius = (value - 32) * 5 / 9;
      case 'K':
        celsius = value - 273.15;
      default:
        throw FormatException('$_errorInvalidTemperatureUnit：$fromUnit');
    }

    switch (toUnit) {
      case '°C':
        return celsius;
      case '°F':
        return celsius * 9 / 5 + 32;
      case 'K':
        return celsius + 273.15;
      default:
        throw FormatException('$_errorInvalidTemperatureUnit：$toUnit');
    }
  }

  /// 格式化换算结果。
  ///
  /// - [precision]：小数精度，默认 6。
  /// - [scientificNotation]：是否强制使用科学计数法，默认 false。
  ///
  /// 极大或极小值会自动切换为科学计数法显示。
  String formatResult(
    double value, {
    int precision = 6,
    bool scientificNotation = false,
  }) {
    if (value.isNaN) return 'Error';
    if (value.isInfinite) return 'Error';

    if (scientificNotation) {
      return _formatScientific(value, precision);
    }

    final absValue = value.abs();
    if ((absValue >= 1e10 && absValue != 0) ||
        (absValue < 1e-10 && absValue != 0)) {
      return _formatScientific(value, precision);
    }

    final factor = math.pow(10, precision).toDouble();
    final rounded = (value * factor).roundToDouble() / factor;
    return _trimTrailingZeros(rounded.toStringAsFixed(precision));
  }

  static String _formatScientific(double value, int precision) {
    final absValue = value.abs();
    if (absValue == 0) return '0';

    final exponent = (math.log(absValue) / math.ln10).floor();
    final mantissa = value / math.pow(10, exponent);
    final factor = math.pow(10, precision).toDouble();
    final roundedMantissa = (mantissa * factor).roundToDouble() / factor;
    final mantissaStr = _trimTrailingZeros(
      roundedMantissa.toStringAsFixed(precision),
    );

    final expSign = exponent >= 0 ? '+' : '-';
    final expValue = exponent.abs().toString().padLeft(2, '0');
    return '${mantissaStr}E$expSign$expValue';
  }

  static String _trimTrailingZeros(String value) {
    if (value.contains('e')) return value;
    if (!value.contains('.')) return value;

    var result = value;
    while (result.endsWith('0')) {
      result = result.substring(0, result.length - 1);
    }
    if (result.endsWith('.')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
