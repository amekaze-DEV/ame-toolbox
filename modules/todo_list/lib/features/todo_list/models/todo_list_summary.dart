/// 首页摘要聚合（运行时派生，不持久化）。
class TodoListSummary {
  const TodoListSummary({
    this.total = 0,
    this.pendingCount = 0,
    this.todayCount = 0,
    this.overdueCount = 0,
  });

  /// 全部待办数（不含历史）。
  final int total;

  /// 未完成数。
  final int pendingCount;

  /// 今日待办数。
  final int todayCount;

  /// 已过期未完成数。
  final int overdueCount;
}