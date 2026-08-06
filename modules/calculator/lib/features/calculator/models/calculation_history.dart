import 'calculator_type.dart';

/// 多功能计算器模块单条历史记录。
///
/// 保存计算成功的输入与结果，最多保留 20 条。
class CalculationHistory {
  /// 输入描述（界面显示字符串，可能包含 `×`、`÷` 等）。
  final String expression;

  /// 格式化后的结果字符串（含数值及单位）。
  final String result;

  /// 记录创建时间（UTC）。
  final DateTime timestamp;

  /// 是否为错误记录（规范要求仅保存成功计算，此字段保留用于兼容与调试）。
  final bool isError;

  /// 角度模式，`'DEG'` 或 `'RAD'`；仅科学计算器使用，其他类型默认 `'DEG'`。
  final String angleMode;

  /// 产生此记录的计算器类型。
  final CalculatorType calculatorType;

  /// 可选的原始输入元数据，用于非科学计算器的历史记录回填。
  ///
  /// 例如单位转换的 `{category, fromValue, fromUnit, toUnit}`，
  /// 几何计算的 `{shape, inputs}` 等。
  final Map<String, dynamic>? metadata;

  const CalculationHistory({
    required this.expression,
    required this.result,
    required this.timestamp,
    this.isError = false,
    this.angleMode = 'DEG',
    this.calculatorType = CalculatorType.scientific,
    this.metadata,
  });

  /// 创建一份除指定字段外均相同的副本。
  CalculationHistory copyWith({
    String? expression,
    String? result,
    DateTime? timestamp,
    bool? isError,
    String? angleMode,
    CalculatorType? calculatorType,
    Map<String, dynamic>? metadata,
  }) {
    return CalculationHistory(
      expression: expression ?? this.expression,
      result: result ?? this.result,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
      angleMode: angleMode ?? this.angleMode,
      calculatorType: calculatorType ?? this.calculatorType,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() {
    return {
      'expression': expression,
      'result': result,
      'timestamp': timestamp.toIso8601String(),
      'isError': isError,
      'angleMode': angleMode,
      'calculatorType': calculatorType.value,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// 从 JSON 反序列化。
  factory CalculationHistory.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    return CalculationHistory(
      expression: json['expression'] as String? ?? '',
      result: json['result'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.utc(1970),
      isError: json['isError'] as bool? ?? false,
      angleMode: json['angleMode'] as String? ?? 'DEG',
      calculatorType: CalculatorTypeExtension.fromString(
          json['calculatorType'] as String?),
      metadata: rawMetadata is Map<String, dynamic>
          ? rawMetadata
          : (rawMetadata as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  String toString() {
    return 'CalculationHistory(expression: $expression, result: $result, '
        'timestamp: $timestamp, isError: $isError, angleMode: $angleMode, '
        'calculatorType: ${calculatorType.value}, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalculationHistory &&
        other.expression == expression &&
        other.result == result &&
        other.timestamp == timestamp &&
        other.isError == isError &&
        other.angleMode == angleMode &&
        other.calculatorType == calculatorType &&
        _mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(
      expression,
      result,
      timestamp,
      isError,
      angleMode,
      calculatorType,
      _metadataHash(metadata),
    );
  }

  static bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  static int _metadataHash(Map<String, dynamic>? metadata) {
    if (metadata == null) return 0;
    return Object.hashAll(
      metadata.entries.map((e) => Object.hash(e.key, e.value)),
    );
  }
}
