import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo_list_summary.dart';
import 'todo_list_provider.dart';
import 'todo_query_service_provider.dart';

/// 首页摘要（派生状态，不持久化）。
final todoSummaryProvider = Provider<TodoListSummary>((ref) {
  final list = ref.watch(todoListProvider);
  final query = ref.watch(todoQueryServiceProvider);
  return query.computeSummary(list.items, DateTime.now());
});