/// 本地通知服务抽象。
///
/// 模块通过此接口申请通知/提醒，无需关心底层平台实现。
/// 实现类位于 core/platform 或 core/notifications，允许使用平台相关代码。
abstract class NotificationService {
  /// 初始化通知服务。
  Future<void> initialize();

  /// 立即显示一条通知。
  Future<void> show(String id, String title, String body);

  /// 在指定时间调度一条通知。
  ///
  /// 若 [scheduledTime] 已过，则立即显示。
  Future<void> schedule(
    String id,
    String title,
    String body,
    DateTime scheduledTime,
  );

  /// 取消指定 id 的待调度通知（已显示的通知不一定能撤回，取决于平台）。
  Future<void> cancel(String id);

  /// 取消所有待调度通知。
  Future<void> cancelAll();
}
