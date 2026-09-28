/// 便签排序方式。
enum NoteSortMode {
  /// 按更新时间倒序（默认）。
  updatedDesc,

  /// 按创建时间倒序。
  createdDesc,

  /// 按标题字母序。
  titleAsc;

  /// 显示名称。
  String get displayName {
    return switch (this) {
      NoteSortMode.updatedDesc => '按更新时间',
      NoteSortMode.createdDesc => '按创建时间',
      NoteSortMode.titleAsc => '按标题',
    };
  }

  /// JSON 序列化标识。
  String get jsonValue => name;

  /// 从 JSON 反序列化。
  ///
  /// 遇到未知值时抛出 [ArgumentError]，避免静默降级导致数据异常被掩盖。
  static NoteSortMode fromJson(String value) {
    return NoteSortMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => throw ArgumentError('Unknown NoteSortMode value: $value'),
    );
  }
}
