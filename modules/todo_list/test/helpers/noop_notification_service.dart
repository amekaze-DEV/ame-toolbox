import 'package:ametoolbox/core/notifications/notification_service.dart';

/// NotificationService no-op 实现（仅用于单元测试）。
///
/// 测试环境不触发真实通知，所有方法空操作。
class NoopNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> show(String id, String title, String body) async {}

  @override
  Future<void> schedule(
    String id,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {}

  @override
  Future<void> cancel(String id) async {}

  @override
  Future<void> cancelAll() async {}
}
