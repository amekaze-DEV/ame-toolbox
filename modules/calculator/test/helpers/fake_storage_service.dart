import 'package:ametoolbox/core/models/layout_config.dart';
import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_state.dart';
import 'package:ametoolbox/core/models/sync_config.dart';
import 'package:ametoolbox/core/models/theme_config.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

/// 测试用内存存储服务。
class FakeStorageService implements StorageService {
  final Map<String, Map<String, dynamic>> _data = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveData(String key, Map<String, dynamic> data) async {
    _data[key] = Map<String, dynamic>.from(data);
  }

  @override
  Future<Map<String, dynamic>?> loadData(String key) async {
    final data = _data[key];
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  @override
  Future<void> deleteData(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clearAll() async => _data.clear();

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
}
