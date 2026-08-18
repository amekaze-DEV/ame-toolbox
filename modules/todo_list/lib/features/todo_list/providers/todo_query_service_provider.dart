import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/todo_query_service.dart';
import 'todo_recurrence_resolver_provider.dart';

/// 注入查询 / 排序 / 摘要服务。
final todoQueryServiceProvider = Provider<TodoQueryService>((ref) {
  return TodoQueryService(resolver: ref.watch(todoRecurrenceResolverProvider));
});