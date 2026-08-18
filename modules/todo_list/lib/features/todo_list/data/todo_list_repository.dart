import 'package:ametoolbox/core/storage/storage_service.dart';

import '../models/todo_item.dart';

/// 待办列表持久化 Repository。
///
/// 通过 [StorageService] 的通用键值接口整体存取，存储 key 为
/// `module_todo_list_items`，以 JSON 列表形式序列化。
class TodoListRepository {
  TodoListRepository({required StorageService storageService})
      : _storage = storageService;

  static const _itemsKey = 'module_todo_list_items';

  final StorageService _storage;

  static const _schemaVersion = 1;

  /// 加载所有待办项，首次使用返回空列表。
  Future<List<TodoItem>> loadAll() async {
    final json = await _storage.loadData(_itemsKey);
    if (json == null) return <TodoItem>[];
    final schemaVersion = json['schemaVersion'] as int? ?? 1;
    assert(schemaVersion == 1, 'Unsupported TodoItem list schema version: $schemaVersion');
    final items = json['items'] as List<dynamic>?;
    if (items == null) return <TodoItem>[];
    return items
        .map((e) => TodoItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 整体保存所有待办项。
  Future<void> saveAll(List<TodoItem> items) async {
    await _storage.saveData(_itemsKey, {
      'schemaVersion': _schemaVersion,
      'items': items.map((e) => e.toJson()).toList(),
    });
  }

  /// 追加或替换单个待办项（按 id 匹配）。
  Future<void> upsert(TodoItem item) async {
    final items = await loadAll();
    final index = items.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }
    await saveAll(items);
  }

  /// 按 id 删除单个待办项。
  Future<void> delete(String id) async {
    final items = await loadAll();
    items.removeWhere((e) => e.id == id);
    await saveAll(items);
  }

  /// 清空所有待办项。
  Future<void> clearAll() async {
    await _storage.deleteData(_itemsKey);
  }
}