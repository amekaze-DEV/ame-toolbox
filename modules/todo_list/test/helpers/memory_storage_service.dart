import 'package:ametoolbox/core/models/layout_config.dart';
import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_state.dart';
import 'package:ametoolbox/core/models/sync_config.dart';
import 'package:ametoolbox/core/models/theme_config.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

/// StorageService 内存实现（仅用于单元测试）。
///
/// 所有数据仅存于内存 Map，不碰 Hive/文件系统，
/// 避免单元测试依赖 Hive 初始化。
class MemoryStorageService implements StorageService {
  final _data = <String, dynamic>{};
  String _deviceId = 'memory-device-id';

  // ── 通用键值 ──
  @override
  Future<void> saveData(String key, Map<String, dynamic> data) async {
    _data[key] = data;
  }

  @override
  Future<Map<String, dynamic>?> loadData(String key) async {
    return _data[key] as Map<String, dynamic>?;
  }

  @override
  Future<void> deleteData(String key) async {
    _data.remove(key);
  }

  // ── ModuleDefinition ──
  @override
  Future<List<ModuleDefinition>> getModuleDefinitions() async {
    return (_data['module_definitions'] as List<dynamic>?)
            ?.cast<ModuleDefinition>() ??
        [];
  }

  @override
  Future<void> setModuleDefinitions(List<ModuleDefinition> definitions) async {
    _data['module_definitions'] = definitions;
  }

  // ── ModuleState ──
  @override
  Future<List<ModuleState>> getModuleStates() async {
    return (_data['module_states'] as List<dynamic>?)?.cast<ModuleState>() ?? [];
  }

  @override
  Future<void> setModuleStates(List<ModuleState> states) async {
    _data['module_states'] = states;
  }

  // ── ThemeConfig ──
  @override
  Future<ThemeConfig?> getThemeConfig() async {
    return _data['theme_config'] as ThemeConfig?;
  }

  @override
  Future<void> setThemeConfig(ThemeConfig config) async {
    _data['theme_config'] = config;
  }

  // ── LayoutConfig ──
  @override
  Future<LayoutConfig?> getLayoutConfig() async {
    return _data['layout_config'] as LayoutConfig?;
  }

  @override
  Future<void> setLayoutConfig(LayoutConfig config) async {
    _data['layout_config'] = config;
  }

  // ── SyncConfig ──
  @override
  Future<SyncConfig?> getSyncConfig() async {
    return _data['sync_config'] as SyncConfig?;
  }

  @override
  Future<void> setSyncConfig(SyncConfig config) async {
    _data['sync_config'] = config;
  }

  // ── WebDAV password ──
  @override
  Future<String?> getWebDavPassword() async => null;

  @override
  Future<void> setWebDavPassword(String password) async {
    // no-op: 测试环境不存储密码
  }

  // ── Device ID ──
  @override
  Future<String?> getDeviceId() async => _deviceId;

  @override
  Future<void> setDeviceId(String deviceId) async {
    _deviceId = deviceId;
  }

  // ── 初始化 ──
  @override
  Future<void> initialize() async {
    // 内存实现无需初始化
  }

  // ── 清空 ──
  @override
  Future<void> clearAll() async {
    _data.clear();
  }
}
