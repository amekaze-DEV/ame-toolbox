import 'package:ametoolbox/core/models/layout_config.dart';
import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_state.dart';
import 'package:ametoolbox/core/models/sync_config.dart';
import 'package:ametoolbox/core/models/theme_config.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

///【临时】StorageService 内存实现（合并主线后删除）。
///
/// 仅供便签模块独立调试使用：读写仅发生在内存，不碰 Hive，
/// 启动轻量、编译快速。
class MemoryStorageService implements StorageService {
  final List<ModuleDefinition> _moduleDefinitions = [];
  final List<ModuleState> _moduleStates = [];
  ThemeConfig? _themeConfig;
  LayoutConfig? _layoutConfig;
  SyncConfig? _syncConfig;
  String? _webDavPassword;
  String? _deviceId;
  final Map<String, Map<String, dynamic>> _data = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<List<ModuleDefinition>> getModuleDefinitions() async =>
      List.of(_moduleDefinitions);

  @override
  Future<void> setModuleDefinitions(List<ModuleDefinition> definitions) async {
    _moduleDefinitions
      ..clear()
      ..addAll(definitions);
  }

  @override
  Future<List<ModuleState>> getModuleStates() async => List.of(_moduleStates);

  @override
  Future<void> setModuleStates(List<ModuleState> states) async {
    _moduleStates
      ..clear()
      ..addAll(states);
  }

  @override
  Future<ThemeConfig?> getThemeConfig() async => _themeConfig;

  @override
  Future<void> setThemeConfig(ThemeConfig config) async =>
      _themeConfig = config;

  @override
  Future<LayoutConfig?> getLayoutConfig() async => _layoutConfig;

  @override
  Future<void> setLayoutConfig(LayoutConfig config) async =>
      _layoutConfig = config;

  @override
  Future<SyncConfig?> getSyncConfig() async => _syncConfig;

  @override
  Future<void> setSyncConfig(SyncConfig config) async => _syncConfig = config;

  @override
  Future<String?> getWebDavPassword() async => _webDavPassword;

  @override
  Future<void> setWebDavPassword(String password) async =>
      _webDavPassword = password;

  @override
  Future<String?> getDeviceId() async => _deviceId;

  @override
  Future<void> setDeviceId(String deviceId) async => _deviceId = deviceId;

  @override
  Future<void> saveData(String key, Map<String, dynamic> data) async =>
      _data[key] = Map<String, dynamic>.of(data);

  @override
  Future<Map<String, dynamic>?> loadData(String key) async {
    final stored = _data[key];
    return stored == null ? null : Map<String, dynamic>.of(stored);
  }

  @override
  Future<void> deleteData(String key) async => _data.remove(key);

  @override
  Future<void> clearAll() async {
    _moduleDefinitions.clear();
    _moduleStates.clear();
    _themeConfig = null;
    _layoutConfig = null;
    _syncConfig = null;
    _webDavPassword = null;
    _deviceId = null;
    _data.clear();
  }
}
