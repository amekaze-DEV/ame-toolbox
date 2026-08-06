/// 多功能计算器模块支持的计算器类型。
///
/// 所有类型在同一模块主页内通过顶部选择器切换。
enum CalculatorType {
  /// 科学计算器：表达式求值、函数、历史记录。
  scientific,

  /// 标准立方米-质量转换：气体流量计常用换算。
  standardCubicToMass,

  /// 单位转换器：长度、重量、温度、面积、体积、速度、时间、角度等。
  unitConverter,

  /// 几何计算器：圆、矩形、长方体、圆柱、圆锥、球、圆筒、棱锥。
  geometry,

  /// 进制转换器：二 / 八 / 十 / 十六进制互转。
  radix,

  /// 汇率计算器：多货币换算、公开源、离线缓存。
  exchangeRate,
}

/// [CalculatorType] 的扩展，提供显示名称等辅助属性。
extension CalculatorTypeExtension on CalculatorType {
  /// 用户可见的中文名称。
  String get displayName {
    switch (this) {
      case CalculatorType.scientific:
        return '科学计算器';
      case CalculatorType.standardCubicToMass:
        return '标准立方米-质量';
      case CalculatorType.unitConverter:
        return '单位转换';
      case CalculatorType.geometry:
        return '几何计算';
      case CalculatorType.radix:
        return '进制转换';
      case CalculatorType.exchangeRate:
        return '汇率计算';
    }
  }

  /// 用于序列化的字符串标识。
  String get value {
    switch (this) {
      case CalculatorType.scientific:
        return 'scientific';
      case CalculatorType.standardCubicToMass:
        return 'standardCubicToMass';
      case CalculatorType.unitConverter:
        return 'unitConverter';
      case CalculatorType.geometry:
        return 'geometry';
      case CalculatorType.radix:
        return 'radix';
      case CalculatorType.exchangeRate:
        return 'exchangeRate';
    }
  }

  /// 从序列化字符串还原枚举值；无法识别时返回 [CalculatorType.scientific]。
  static CalculatorType fromString(String? value) {
    return CalculatorType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CalculatorType.scientific,
    );
  }
}
