/// 几何计算器支持的几何体类型。
enum GeometryShape {
  /// 圆。
  circle,

  /// 矩形。
  rectangle,

  /// 长方体。
  cuboid,

  /// 圆柱。
  cylinder,

  /// 圆锥。
  cone,

  /// 球。
  sphere,

  /// 圆筒（空心圆柱）。
  hollowCylinder,

  /// 棱锥（正多边形底）。
  pyramid,
}

/// [GeometryShape] 的扩展，提供显示名称等辅助属性。
extension GeometryShapeExtension on GeometryShape {
  /// 用于序列化的字符串标识。
  String get value => name;

  /// 从序列化字符串还原枚举值；无法识别时返回 [GeometryShape.circle]。
  static GeometryShape fromString(String? value) {
    return GeometryShape.values.firstWhere(
      (shape) => shape.value == value,
      orElse: () => GeometryShape.circle,
    );
  }

  /// 用户可见的中文名称。
  String get displayName {
    switch (this) {
      case GeometryShape.circle:
        return '圆';
      case GeometryShape.rectangle:
        return '矩形';
      case GeometryShape.cuboid:
        return '长方体';
      case GeometryShape.cylinder:
        return '圆柱';
      case GeometryShape.cone:
        return '圆锥';
      case GeometryShape.sphere:
        return '球';
      case GeometryShape.hollowCylinder:
        return '圆筒';
      case GeometryShape.pyramid:
        return '棱锥';
    }
  }
}

/// 几何计算结果。
class GeometryResult {
  /// 计算得到的各项量值，键为量的名称（如“面积”），值为计算结果。
  final Map<String, double> results;

  /// 错误信息；计算成功时为 null。
  final String? error;

  const GeometryResult({
    this.results = const {},
    this.error,
  });

  /// 构造一个仅包含错误信息的结果。
  factory GeometryResult.error(String message) = _ErrorGeometryResult;

  /// 本次计算是否出错。
  bool get isError => error != null;

  @override
  String toString() =>
      isError ? 'GeometryResult(error: $error)' : 'GeometryResult(results: $results)';
}

class _ErrorGeometryResult extends GeometryResult {
  _ErrorGeometryResult(String message) : super(error: message);
}
