import 'package:ametoolbox/core/storage/storage_service.dart';

import '../models/shift_config.dart';

/// 倒班助手配置 Repository。
///
/// 通过 [StorageService] 持久化模块配置，key 前缀遵循
/// `module_shift_assistant_` 规范。
class ShiftConfigRepository {
  final StorageService _storage;

  static const _configKey = 'module_shift_assistant_config';

  ShiftConfigRepository({required this._storage});

  Future<ShiftConfig> load() async {
    final data = await _storage.loadData(_configKey);
    if (data == null) return ShiftConfig.defaults();
    return ShiftConfig.fromJson(data);
  }

  Future<void> save(ShiftConfig config) async {
    await _storage.saveData(_configKey, config.toJson());
  }
}
