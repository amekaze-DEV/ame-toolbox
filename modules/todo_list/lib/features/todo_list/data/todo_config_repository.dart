import 'package:ametoolbox/core/storage/storage_service.dart';

import '../models/todo_config.dart';

/// 待办配置持久化 Repository。
///
/// 通过 [StorageService] 的通用键值接口存取，存储 key 为
/// `module_todo_list_config`，首次加载时写入默认分类。
class TodoConfigRepository {
  TodoConfigRepository({required StorageService storageService})
      : _storage = storageService;

  static const _configKey = 'module_todo_list_config';

  final StorageService _storage;

  /// 加载配置，首次使用则写入并返回默认配置。
  Future<TodoConfig> load() async {
    final json = await _storage.loadData(_configKey);
    if (json != null) {
      return TodoConfig.fromJson(json);
    }
    // 首次使用：写入默认配置
    final config = TodoConfig();
    await _storage.saveData(_configKey, config.toJson());
    return config;
  }

  /// 保存配置。
  Future<void> save(TodoConfig config) async {
    await _storage.saveData(_configKey, config.toJson());
  }

  /// 重置为默认配置。
  Future<TodoConfig> reset() async {
    final config = TodoConfig();
    await _storage.saveData(_configKey, config.toJson());
    return config;
  }
}