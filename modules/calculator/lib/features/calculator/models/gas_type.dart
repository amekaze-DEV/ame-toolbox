/// 标准立方米-质量转换支持的气体类型。
enum GasType {
  /// 天然气（以甲烷近似）。
  naturalGas,

  /// 干空气。
  air,

  /// 氧气（O₂）。
  oxygen,

  /// 氮气（N₂）。
  nitrogen,

  /// 氢气（H₂）。
  hydrogen,

  /// 二氧化碳（CO₂）。
  carbonDioxide,

  /// 丙烷（C₃H₈）。
  propane,

  /// 自定义气体，摩尔质量由用户输入。
  custom,
}

/// [GasType] 的扩展，提供显示名称与摩尔质量等辅助属性。
extension GasTypeExtension on GasType {
  /// 用户可见的中文名称。
  String get displayName {
    switch (this) {
      case GasType.naturalGas:
        return '天然气（甲烷）';
      case GasType.air:
        return '空气';
      case GasType.oxygen:
        return '氧气';
      case GasType.nitrogen:
        return '氮气';
      case GasType.hydrogen:
        return '氢气';
      case GasType.carbonDioxide:
        return '二氧化碳';
      case GasType.propane:
        return '丙烷';
      case GasType.custom:
        return '自定义';
    }
  }

  /// 默认摩尔质量（g/mol）。
  ///
  /// 仅内置气体有固定值，[GasType.custom] 返回 `null`，需由调用方提供。
  double? get molarMass {
    switch (this) {
      case GasType.naturalGas:
        return 16.04;
      case GasType.air:
        return 28.97;
      case GasType.oxygen:
        return 31.998;
      case GasType.nitrogen:
        return 28.013;
      case GasType.hydrogen:
        return 2.016;
      case GasType.carbonDioxide:
        return 44.01;
      case GasType.propane:
        return 44.10;
      case GasType.custom:
        return null;
    }
  }

  /// 用于序列化的字符串标识。
  String get value {
    switch (this) {
      case GasType.naturalGas:
        return 'naturalGas';
      case GasType.air:
        return 'air';
      case GasType.oxygen:
        return 'oxygen';
      case GasType.nitrogen:
        return 'nitrogen';
      case GasType.hydrogen:
        return 'hydrogen';
      case GasType.carbonDioxide:
        return 'carbonDioxide';
      case GasType.propane:
        return 'propane';
      case GasType.custom:
        return 'custom';
    }
  }

  /// 从序列化字符串还原枚举值；无法识别时返回 [GasType.custom]。
  static GasType fromString(String? value) {
    return GasType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => GasType.custom,
    );
  }
}
