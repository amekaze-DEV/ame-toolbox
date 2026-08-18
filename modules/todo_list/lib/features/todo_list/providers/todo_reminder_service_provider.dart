import 'package:ametoolbox/core/providers/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/todo_reminder_service.dart';
import 'todo_recurrence_resolver_provider.dart';

/// 注入提醒服务。
final todoReminderServiceProvider = Provider<TodoReminderService>((ref) {
  return TodoReminderService(
    notificationService: ref.watch(notificationServiceProvider),
    resolver: ref.watch(todoRecurrenceResolverProvider),
  );
});