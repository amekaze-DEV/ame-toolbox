import 'dart:async';

import 'package:local_notifier/local_notifier.dart';

import 'package:ametoolbox/core/notifications/notification_service.dart';

/// 基于 `local_notifier` 的桌面端通知服务实现。
///
/// - `show()` 立即弹出系统通知。
/// - `schedule()` 通过应用内 Timer 实现，适用于应用运行期间的提醒。
/// - 取消待调度通知会清除 Timer；已显示通知的撤回能力取决于平台。
class LocalNotificationService implements NotificationService {
  LocalNotificationService({this._appName = 'AMEToolbox'});

  final String _appName;
  bool _initialized = false;

  final Map<String, Timer> _scheduledTimers = {};
  final Map<String, LocalNotification> _shownNotifications = {};

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await localNotifier.setup(
      appName: _appName,
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
    _initialized = true;
  }

  @override
  Future<void> show(String id, String title, String body) async {
    await _ensureInitialized();

    final notification = LocalNotification(
      identifier: id,
      title: title,
      body: body,
    );

    notification.onShow = () {
      _scheduledTimers.remove(id);
    };
    notification.onClose = (_) {
      _shownNotifications.remove(id);
    };
    notification.onClick = () {
      // 点击通知时可扩展为回到应用主窗口。
    };

    _shownNotifications[id] = notification;
    await notification.show();
  }

  @override
  Future<void> schedule(
    String id,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    await _ensureInitialized();

    // 取消同 id 的已有调度，避免重复。
    await cancel(id);

    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) {
      await show(id, title, body);
      return;
    }

    final delay = scheduledTime.difference(now);
    _scheduledTimers[id] = Timer(delay, () async {
      await show(id, title, body);
    });
  }

  @override
  Future<void> cancel(String id) async {
    _scheduledTimers[id]?.cancel();
    _scheduledTimers.remove(id);

    final shown = _shownNotifications.remove(id);
    if (shown != null) {
      // local_notifier 的 close 方法在部分平台可用。
      await shown.close();
    }
  }

  @override
  Future<void> cancelAll() async {
    for (final timer in _scheduledTimers.values) {
      timer.cancel();
    }
    _scheduledTimers.clear();

    for (final notification in _shownNotifications.values) {
      await notification.close();
    }
    _shownNotifications.clear();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
}
