import 'package:ametoolbox/core/notifications/notification_service.dart';

import '../models/todo_config.dart';
import '../models/todo_item.dart';
import 'todo_recurrence_resolver.dart';

/// 到期提醒服务。
///
/// 负责计算提醒时间、维护"待办 → 通知 id"映射，并在状态变更时重调度/取消。
/// 实际调度统一委托底座 [NotificationService]。
///
/// 提醒约定：
/// - 总开关：仅当 [TodoConfig.remindEnabled] 与 [TodoItem.remindEnabled]
///   （单条开关）均为 true 时调度；
/// - 执行时刻：每次命中日（一次性为 [TodoItem.dueDate]，循环为下一最近命中日）
///   按 [TodoItem.executionTimeMinutes] 计算执行时刻；
/// - 一条待办最多触发两次提醒：
///   - 执行时刻提醒：在命中日的执行时刻触发（[TodoItem.remindAtExecution] 控制）；
///   - 提前提醒：在执行时刻前 N 分钟触发（[TodoItem.remindEarly] 控制，
///     N = [TodoItem.remindMinutes] 或全局默认）；
/// - 通知 id：`module_todo_list_item_<itemId>`（提前 `_early`、执行时刻 `_onTime`）。
class TodoReminderService {
  TodoReminderService({
    required NotificationService notificationService,
    required TodoRecurrenceResolver resolver,
  })  : _notification = notificationService,
        // ignore: prefer_initializing_formals
        _resolver = resolver;

  final NotificationService _notification;
  final TodoRecurrenceResolver _resolver;

  /// 基础通知 id。
  static String notificationId(String itemId) =>
      'module_todo_list_item_$itemId';

  /// 提前提醒通知 id。
  static String earlyNotificationId(String itemId) =>
      '${notificationId(itemId)}_early';

  /// 执行时刻提醒通知 id。
  static String onTimeNotificationId(String itemId) =>
      '${notificationId(itemId)}_onTime';

  /// 计算 [item] 下一次命中日（DateOnly）；无命中返回 null。
  DateTime? _nextHitDay(TodoItem item, DateTime now) {
    if (item.isCompleted || item.isArchived) return null;
    final today = DateTime(now.year, now.month, now.day);
    // 从今天起往后查 1 年内的命中日，取最近一次。
    final horizon = today.add(const Duration(days: 366));
    final dates = _resolver.resolve(item, today, horizon);
    return dates.isEmpty ? null : dates.first;
  }

  static DateTime _atTimeOfDay(DateTime day, int minutesOfDay) => DateTime(
        day.year,
        day.month,
        day.day,
        minutesOfDay ~/ 60,
        minutesOfDay % 60,
      );

  /// 执行时刻提醒时间 = 下次命中日 + 执行时刻。
  ///
  /// 全局开关关、单条开关关、执行时刻提醒关或无命中时返回 null。
  DateTime? executionReminderTime(
    TodoItem item,
    TodoConfig config,
    DateTime now,
  ) {
    if (!config.remindEnabled || !item.remindEnabled) return null;
    if (!item.remindAtExecution) return null;
    final hit = _nextHitDay(item, now);
    if (hit == null) return null;
    return _atTimeOfDay(hit, item.executionTimeMinutes);
  }

  /// 提前提醒时间 = 下次命中日执行时刻 − 提前分钟数。
  ///
  /// 全局开关关、单条开关关、提前提醒关或无命中时返回 null。
  DateTime? earlyReminderTime(
    TodoItem item,
    TodoConfig config,
    DateTime now,
  ) {
    if (!config.remindEnabled || !item.remindEnabled) return null;
    if (!item.remindEarly) return null;
    final hit = _nextHitDay(item, now);
    if (hit == null) return null;
    final minutes = item.remindMinutes ?? config.defaultRemindMinutes;
    return _atTimeOfDay(hit, item.executionTimeMinutes)
        .subtract(Duration(minutes: minutes));
  }

  /// 为单个待办调度提醒：执行时刻 + 提前两种，按需调度或取消。
  Future<void> scheduleForItem(
    TodoItem item,
    TodoConfig config,
    DateTime now,
  ) async {
    final onTime = executionReminderTime(item, config, now);
    await _scheduleOrCancel(
      onTimeNotificationId(item.id),
      item.title,
      onTime,
      now,
    );
    final early = earlyReminderTime(item, config, now);
    await _scheduleOrCancel(
      earlyNotificationId(item.id),
      item.title,
      early,
      now,
    );
  }

  Future<void> _scheduleOrCancel(
    String id,
    String title,
    DateTime? time,
    DateTime now,
  ) async {
    if (time == null || !time.isAfter(now)) {
      await _notification.cancel(id);
      return;
    }
    await _notification.schedule(id, title, '待办提醒：$title', time);
  }

  /// 批量调度全部待办的提醒。
  Future<void> scheduleAll(
    List<TodoItem> items,
    TodoConfig config,
    DateTime now,
  ) async {
    for (final item in items) {
      await scheduleForItem(item, config, now);
    }
  }

  /// 取消指定待办的通知（含提前与执行时刻两个 id）。
  Future<void> cancel(String itemId) async {
    await _notification.cancel(notificationId(itemId));
    await _notification.cancel(earlyNotificationId(itemId));
    await _notification.cancel(onTimeNotificationId(itemId));
  }

  /// 取消本模块全部通知。
  Future<void> cancelAll() => _notification.cancelAll();
}
