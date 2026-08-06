import 'dart:convert';

import 'package:ametoolbox/core/models/layout_config.dart';
import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_state.dart';
import 'package:ametoolbox/core/models/sync_config.dart';
import 'package:ametoolbox/core/models/theme_config.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

/// 内存存储服务实现。
///
/// 仅用于子项目独立运行与测试，不持久化到磁盘；
/// 进程重启后数据丢失，但足够验证模块 UI 与状态管理。
class MemoryStorageService implements StorageService {
  final Map<String, dynamic> _data = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<List<ModuleDefinition>> getModuleDefinitions() async => [];

  @override
  Future<void> setModuleDefinitions(List<ModuleDefinition> definitions) async {}

  @override
  Future<List<ModuleState>> getModuleStates() async => [];

  @override
  Future<void> setModuleStates(List<ModuleState> states) async {}

  @override
  Future<ThemeConfig?> getThemeConfig() async => null;

  @override
  Future<void> setThemeConfig(ThemeConfig config) async {}

  @override
  Future<LayoutConfig?> getLayoutConfig() async => null;

  @override
  Future<void> setLayoutConfig(LayoutConfig config) async {}

  @override
  Future<SyncConfig?> getSyncConfig() async => null;

  @override
  Future<void> setSyncConfig(SyncConfig config) async {}

  @override
  Future<String?> getWebDavPassword() async => null;

  @override
  Future<void> setWebDavPassword(String password) async {}

  @override
  Future<String?> getDeviceId() async => null;

  @override
  Future<void> setDeviceId(String deviceId) async {}

  @override
  Future<void> saveData(String key, Map<String, dynamic> data) async {
    // 深拷贝，避免外部引用修改已保存的数据。
    _data[key] = jsonDecode(jsonEncode(data));
  }

  @override
  Future<Map<String, dynamic>?> loadData(String key) async {
    final value = _data[key];
    if (value == null) return null;
    return (value as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v),
    );
  }

  @override
  Future<void> deleteData(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clearAll() async {
    _data.clear();
  }
}
