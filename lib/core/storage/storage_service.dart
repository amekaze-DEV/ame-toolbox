import 'package:ametoolbox/core/models/layout_config.dart';
import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_state.dart';
import 'package:ametoolbox/core/models/sync_config.dart';
import 'package:ametoolbox/core/models/theme_config.dart';

/// 本地持久化存储抽象接口。
///
/// 所有数据读写通过此接口，禁止 UI 层或模块直接访问 Hive/文件系统。
abstract class StorageService {
  /// 初始化存储。
  Future<void> initialize();

  // ── ModuleDefinition ──
  Future<List<ModuleDefinition>> getModuleDefinitions();
  Future<void> setModuleDefinitions(List<ModuleDefinition> definitions);

  // ── ModuleState ──
  Future<List<ModuleState>> getModuleStates();
  Future<void> setModuleStates(List<ModuleState> states);

  // ── ThemeConfig ──
  Future<ThemeConfig?> getThemeConfig();
  Future<void> setThemeConfig(ThemeConfig config);

  // ── LayoutConfig ──
  Future<LayoutConfig?> getLayoutConfig();
  Future<void> setLayoutConfig(LayoutConfig config);

  // ── SyncConfig ──
  Future<SyncConfig?> getSyncConfig();
  Future<void> setSyncConfig(SyncConfig config);

  // ── WebDAV password ──
  Future<String?> getWebDavPassword();
  Future<void> setWebDavPassword(String password);

  // ── Device ID backup ──
  Future<String?> getDeviceId();
  Future<void> setDeviceId(String deviceId);

  // ── 模块业务数据（通用键值）──
  Future<void> saveData(String key, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> loadData(String key);
  Future<void> deleteData(String key);

  /// 清空所有数据。
  Future<void> clearAll();
}
