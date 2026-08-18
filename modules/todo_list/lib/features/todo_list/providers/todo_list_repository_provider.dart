import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/todo_list_repository.dart';

/// 注入待办列表 Repository。
final todoListRepositoryProvider = Provider<TodoListRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return TodoListRepository(storageService: storage);
});