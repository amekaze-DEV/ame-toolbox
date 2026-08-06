import 'package:calculator_module/features/calculator/models/gas_type.dart';

/// 标准立方米（Nm³）与气体质量之间的换算服务。
///
/// 基于理想气体标准摩尔体积计算，默认标准状态为 0°C、101.325 kPa，
/// 标准摩尔体积 [defaultStandardMolarVolume] = 22.414 L/mol。
class StandardCubicMassService {
  /// 默认标准摩尔体积，单位 L/mol。
  static const double defaultStandardMolarVolume = 22.414;

  static const String _errorMolarMassPositive = '摩尔质量必须大于 0';
  static const String _errorVmPositive = '标准摩尔体积必须大于 0';
  static const String _errorVolumeNonNegative = '标准体积必须大于或等于 0';
  static const String _errorMassNonNegative = '质量必须大于或等于 0';
  static const String _errorUnknownVolumeUnit = '未知标准体积单位';
  static const String _errorUnknownMassUnit = '未知质量单位';

  const StandardCubicMassService();

  /// 根据质量计算标准体积（Nm³）。
  ///
  /// - [mass]：质量数值。
  /// - [massUnit]：质量单位，支持 `kg`、`g`、`t`、`lb`、`oz`。
  /// - [molarMass]：摩尔质量，单位 g/mol，必须大于 0。
  /// - [vm]：标准摩尔体积，单位 L/mol，必须大于 0。
  double calculateVolume(
    double mass,
    String massUnit,
    double molarMass,
    double vm,
  ) {
    _validateMolarMass(molarMass);
    _validateVm(vm);
    _validateMass(mass);

    final massKg = convertMassToKg(mass, massUnit);
    return massKg * vm / molarMass;
  }

  /// 根据标准体积计算质量（kg）。
  ///
  /// - [volume]：标准体积数值。
  /// - [volumeUnit]：体积单位，支持 `Nm³`、`m³`、`L`。
  /// - [molarMass]：摩尔质量，单位 g/mol，必须大于 0。
  /// - [vm]：标准摩尔体积，单位 L/mol，必须大于 0。
  double calculateMass(
    double volume,
    String volumeUnit,
    double molarMass,
    double vm,
  ) {
    _validateMolarMass(molarMass);
    _validateVm(vm);
    _validateVolume(volume);

    final volumeNm3 = convertVolumeToNm3(volume, volumeUnit);
    return volumeNm3 * molarMass / vm;
  }

  /// 将标准体积单位换算为 Nm³。
  ///
  /// 支持单位：`Nm³`、`m³`、`L`（大小写敏感）。
  double convertVolumeToNm3(double value, String unit) {
    switch (unit) {
      case 'Nm³':
      case 'm³':
        return value;
      case 'L':
        return value * 1e-3;
      default:
        throw ArgumentError('$_errorUnknownVolumeUnit: $unit');
    }
  }

  /// 将质量单位换算为 kg。
  ///
  /// 支持单位：`kg`、`g`、`t`、`lb`、`oz`（大小写敏感）。
  double convertMassToKg(double value, String unit) {
    switch (unit) {
      case 'kg':
        return value;
      case 'g':
        return value * 1e-3;
      case 't':
        return value * 1000;
      case 'lb':
        return value * 0.45359237;
      case 'oz':
        return value * 0.0283495231;
      default:
        throw ArgumentError('$_errorUnknownMassUnit: $unit');
    }
  }

  /// 计算推导标准密度 ρ（kg/Nm³）。
  ///
  /// ρ = M / Vm。
  double calculateDensity(double molarMass, double vm) {
    _validateMolarMass(molarMass);
    _validateVm(vm);
    return molarMass / vm;
  }

  /// 根据 [GasType] 获取默认摩尔质量（g/mol）。
  ///
  /// [GasType.custom] 返回 `null`。
  double? resolveMolarMass(GasType gasType) => gasType.molarMass;

  void _validateMolarMass(double molarMass) {
    if (molarMass <= 0) {
      throw ArgumentError(_errorMolarMassPositive);
    }
  }

  void _validateVm(double vm) {
    if (vm <= 0) {
      throw ArgumentError(_errorVmPositive);
    }
  }

  void _validateVolume(double volume) {
    if (volume < 0) {
      throw ArgumentError(_errorVolumeNonNegative);
    }
  }

  void _validateMass(double mass) {
    if (mass < 0) {
      throw ArgumentError(_errorMassNonNegative);
    }
  }
}
