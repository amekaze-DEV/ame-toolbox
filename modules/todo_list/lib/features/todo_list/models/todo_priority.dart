/// 待办优先级（5 级）。
///
/// 颜色标识：
/// - highest: `colorScheme.error`
/// - high: `colorScheme.errorContainer`
/// - medium: `colorScheme.tertiary`
/// - normal: `colorScheme.onSurfaceVariant`
/// - daily: `colorScheme.secondary`
enum TodoPriority {
  highest,
  high,
  medium,
  normal,
  daily;

  /// 默认显示顺序（按枚举声明顺序）。
  /// 日常置顶选项由 [TodoQueryService] 处理。

  String get displayName {
    return switch (this) {
      TodoPriority.highest => '最高',
      TodoPriority.high => '高',
      TodoPriority.medium => '中',
      TodoPriority.normal => '一般',
      TodoPriority.daily => '日常',
    };
  }

  /// JSON 序列化标识。
  String get jsonValue => name;

  /// 从 JSON 反序列化。
  ///
  /// 遇到未知值时抛出 [ArgumentError]，避免静默降级导致数据异常被掩盖。
  static TodoPriority fromJson(String value) {
    return TodoPriority.values.firstWhere(
      (p) => p.name == value,
      orElse: () => throw ArgumentError('Unknown TodoPriority value: $value'),
    );
  }
}