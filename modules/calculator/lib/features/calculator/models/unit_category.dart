/// 单位转换器支持的单位类别。
///
/// 包含科学计算器模块中“单位转换器”功能所需的全部 8 个类别。
enum UnitCategory {
  /// 长度：mm、cm、m、km、in、ft、yd、mi 等。
  length,

  /// 重量：mg、g、kg、t、oz、lb、st 等。
  weight,

  /// 温度：°C、°F、K。
  temperature,

  /// 面积：mm²、cm²、m²、ha、km²、in²、ft²、ac 等。
  area,

  /// 体积：mL、L、m³、cm³、ft³、gal(US)、pt(US) 等。
  volume,

  /// 速度：m/s、km/h、mph、kn、ft/s 等。
  speed,

  /// 时间：ms、s、min、h、d、wk、mo、y 等。
  time,

  /// 角度：deg、rad、grad。
  angle,
}

/// [UnitCategory] 的扩展，提供用户可见名称与支持的单位符号列表。
extension UnitCategoryExtension on UnitCategory {
  /// 用户可见的中文名称。
  String get displayName {
    switch (this) {
      case UnitCategory.length:
        return '长度';
      case UnitCategory.weight:
        return '重量';
      case UnitCategory.temperature:
        return '温度';
      case UnitCategory.area:
        return '面积';
      case UnitCategory.volume:
        return '体积';
      case UnitCategory.speed:
        return '速度';
      case UnitCategory.time:
        return '时间';
      case UnitCategory.angle:
        return '角度';
    }
  }

  /// 用于序列化的字符串标识。
  String get value => name;

  /// 从序列化字符串还原枚举值；无法识别时返回 [UnitCategory.length]。
  static UnitCategory fromString(String? value) {
    return UnitCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => UnitCategory.length,
    );
  }

  /// 单位符号到中文名称的映射。
  Map<String, String> get unitDisplayNames {
    switch (this) {
      case UnitCategory.length:
        return const {
          'mm': '毫米',
          'cm': '厘米',
          'm': '米',
          'km': '千米',
          'in': '英寸',
          'ft': '英尺',
          'yd': '码',
          'mi': '英里',
        };
      case UnitCategory.weight:
        return const {
          'mg': '毫克',
          'g': '克',
          'kg': '千克',
          't': '吨',
          'oz': '盎司',
          'lb': '磅',
          'st': '英石',
        };
      case UnitCategory.temperature:
        return const {
          '°C': '摄氏度',
          '°F': '华氏度',
          'K': '开尔文',
        };
      case UnitCategory.area:
        return const {
          'mm²': '平方毫米',
          'cm²': '平方厘米',
          'm²': '平方米',
          'ha': '公顷',
          'km²': '平方千米',
          'in²': '平方英寸',
          'ft²': '平方英尺',
          'ac': '英亩',
        };
      case UnitCategory.volume:
        return const {
          'mL': '毫升',
          'L': '升',
          'm³': '立方米',
          'cm³': '立方厘米',
          'ft³': '立方英尺',
          'gal(US)': '美制加仑',
          'pt(US)': '美制品脱',
        };
      case UnitCategory.speed:
        return const {
          'm/s': '米每秒',
          'km/h': '千米每小时',
          'mph': '英里每小时',
          'kn': '节',
          'ft/s': '英尺每秒',
        };
      case UnitCategory.time:
        return const {
          'ms': '毫秒',
          's': '秒',
          'min': '分',
          'h': '小时',
          'd': '天',
          'wk': '周',
          'mo': '月',
          'y': '年',
        };
      case UnitCategory.angle:
        return const {
          'deg': '度',
          'rad': '弧度',
          'grad': '百分度',
        };
    }
  }

  /// 该类别下支持的所有单位符号列表，顺序按规格定义。
  List<String> get units {
    switch (this) {
      case UnitCategory.length:
        return const ['mm', 'cm', 'm', 'km', 'in', 'ft', 'yd', 'mi'];
      case UnitCategory.weight:
        return const ['mg', 'g', 'kg', 't', 'oz', 'lb', 'st'];
      case UnitCategory.temperature:
        return const ['°C', '°F', 'K'];
      case UnitCategory.area:
        return const ['mm²', 'cm²', 'm²', 'ha', 'km²', 'in²', 'ft²', 'ac'];
      case UnitCategory.volume:
        return const ['mL', 'L', 'm³', 'cm³', 'ft³', 'gal(US)', 'pt(US)'];
      case UnitCategory.speed:
        return const ['m/s', 'km/h', 'mph', 'kn', 'ft/s'];
      case UnitCategory.time:
        return const ['ms', 's', 'min', 'h', 'd', 'wk', 'mo', 'y'];
      case UnitCategory.angle:
        return const ['deg', 'rad', 'grad'];
    }
  }
}
