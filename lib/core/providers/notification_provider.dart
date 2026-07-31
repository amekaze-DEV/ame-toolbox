import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/notifications/local_notification_service.dart';
import 'package:ametoolbox/core/notifications/notification_service.dart';

/// 通知服务 Provider。
///
/// 模块通过 [notificationServiceProvider] 获取服务实例，
/// 调用 [NotificationService.show] / [schedule] / [cancel] 等方法。
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => LocalNotificationService(),
);
