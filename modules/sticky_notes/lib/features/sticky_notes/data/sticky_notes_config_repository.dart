import 'package:ametoolbox/core/storage/storage_service.dart';

import '../models/sticky_notes_config.dart';

/// 便签配置持久化 Repository。
///
/// 通过 [StorageService] 的通用键值接口存取，存储 key 为
/// `module_sticky_notes_config`，首次加载时写入默认分类。
class StickyNotesConfigRepository {
  StickyNotesConfigRepository({required StorageService storageService})
      : _storage = storageService;

  static const _configKey = 'module_sticky_notes_config';

  final StorageService _storage;

  /// 加载配置，首次使用则写入并返回默认配置。
  Future<StickyNotesConfig> load() async {
    final json = await _storage.loadData(_configKey);
    if (json != null) {
      return StickyNotesConfig.fromJson(json);
    }
    // 首次使用：写入默认配置
    final config = StickyNotesConfig();
    await _storage.saveData(_configKey, config.toJson());
    return config;
  }

  /// 保存配置。
  Future<void> save(StickyNotesConfig config) async {
    await _storage.saveData(_configKey, config.toJson());
  }

  /// 重置为默认配置。
  Future<StickyNotesConfig> reset() async {
    final config = StickyNotesConfig();
    await _storage.saveData(_configKey, config.toJson());
    return config;
  }
}
