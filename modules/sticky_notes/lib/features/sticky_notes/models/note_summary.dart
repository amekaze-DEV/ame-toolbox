/// 首页摘要聚合（运行时派生，不持久化）。
class NoteSummary {
  const NoteSummary({
    this.total = 0,
    this.pinnedCount = 0,
    this.categoryCount = 0,
  });

  /// 便签总数。
  final int total;

  /// 置顶数。
  final int pinnedCount;

  /// 分类数。
  final int categoryCount;
}
