import 'package:flutter_test/flutter_test.dart';
import '../helpers/memory_storage_service.dart';
import 'package:todo_list_module/features/todo_list/data/todo_list_repository.dart';
import 'package:todo_list_module/features/todo_list/models/todo_item.dart';
import 'package:todo_list_module/features/todo_list/models/todo_priority.dart';

void main() {
  group('TodoListRepository', () {
    late MemoryStorageService storage;
    late TodoListRepository repository;

    setUp(() {
      storage = MemoryStorageService();
      repository = TodoListRepository(storageService: storage);
    });

    TodoItem makeItem(String id, String title) {
      final now = DateTime(2026, 8, 12);
      return TodoItem(
        id: id,
        title: title,
        priority: TodoPriority.medium,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('首次 loadAll 返回空列表', () async {
      final items = await repository.loadAll();
      expect(items, isEmpty);
    });

    test('saveAll 与 loadAll 往返正确', () async {
      final items = [
        makeItem('todo-1', '任务一'),
        makeItem('todo-2', '任务二'),
      ];
      await repository.saveAll(items);

      final restored = await repository.loadAll();
      expect(restored.length, 2);
      expect(restored.map((e) => e.id).toList(), ['todo-1', 'todo-2']);

      final stored = await storage.loadData('module_todo_list_items');
      expect(stored!['schemaVersion'], 1);
    });

    test('upsert 新增待办项', () async {
      await repository.upsert(makeItem('todo-1', '任务一'));
      final items = await repository.loadAll();
      expect(items.length, 1);
      expect(items.first.title, '任务一');
    });

    test('upsert 更新已有待办项', () async {
      await repository.upsert(makeItem('todo-1', '任务一'));
      await repository.upsert(makeItem('todo-1', '任务一已更新'));

      final items = await repository.loadAll();
      expect(items.length, 1);
      expect(items.first.title, '任务一已更新');
    });

    test('delete 删除指定待办项', () async {
      await repository.upsert(makeItem('todo-1', '任务一'));
      await repository.upsert(makeItem('todo-2', '任务二'));
      await repository.delete('todo-1');

      final items = await repository.loadAll();
      expect(items.length, 1);
      expect(items.first.id, 'todo-2');
    });

    test('clearAll 清空所有待办项', () async {
      await repository.upsert(makeItem('todo-1', '任务一'));
      await repository.clearAll();

      final items = await repository.loadAll();
      expect(items, isEmpty);
      expect(await storage.loadData('module_todo_list_items'), isNull);
    });
  });
}