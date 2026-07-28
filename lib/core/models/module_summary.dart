/// 模块主页卡片摘要数据。
class ModuleSummary {
  const ModuleSummary({
    required this.label,
    required this.value,
    this.unit,
  });

  /// 摘要标签，如"今日产线计数"。
  final String label;

  /// 摘要数值，如"1,248"。
  final String value;

  /// 单位，如"件"（可选）。
  final String? unit;
}
