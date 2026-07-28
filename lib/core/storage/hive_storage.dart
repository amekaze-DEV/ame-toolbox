import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:ametoolbox/core/constants.dart';
import 'package:ametoolbox/core/models/layout_config.dart';
import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_state.dart';
import 'package:ametoolbox/core/models/sync_config.dart';
import 'package:ametoolbox/core/models/theme_config.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

/// 基于 Hive 的 [StorageService] 实现。
///
/// 使用 [flutter_secure_storage] 存储敏感字段（WebDAV 密码、设备 ID 备份），
/// 其余结构化数据存储在 Hive Box 中。
class HiveStorage implements StorageService {
  static const _themeBoxName = 'theme_config';
  static const _layoutBoxName = 'layout_config';
  static const _syncBoxName = 'sync_config';
  static const _moduleDefBoxName = 'module_definitions';
  static const _moduleStateBoxName = 'module_states';
  static const _moduleDataBoxName = 'module_data';

  static const _configKey = 'config';
  static const _webDavPasswordKey = 'webdav_password';
  static const _deviceIdKey = 'device_id_backup';

  static bool _adaptersRegistered = false;

  final FlutterSecureStorage _secureStorage;

  late Box<ThemeConfig> _themeBox;
  late Box<LayoutConfig> _layoutBox;
  late Box<SyncConfig> _syncBox;
  late Box<ModuleDefinition> _moduleDefBox;
  late Box<ModuleState> _moduleStateBox;
  late Box<String> _moduleDataBox;

  HiveStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
    _registerAdapters();

    _themeBox = await Hive.openBox<ThemeConfig>(_themeBoxName);
    _layoutBox = await Hive.openBox<LayoutConfig>(_layoutBoxName);
    _syncBox = await Hive.openBox<SyncConfig>(_syncBoxName);
    _moduleDefBox = await Hive.openBox<ModuleDefinition>(_moduleDefBoxName);
    _moduleStateBox = await Hive.openBox<ModuleState>(_moduleStateBoxName);
    _moduleDataBox = await Hive.openBox<String>(_moduleDataBoxName);

    await _ensureDefaults();
  }

  void _registerAdapters() {
    if (_adaptersRegistered) return;

    Hive.registerAdapter(ModuleDefinitionAdapter());
    Hive.registerAdapter(ModuleStateAdapter());
    Hive.registerAdapter(LayoutConfigAdapter());
    Hive.registerAdapter(AppThemeModeAdapter());
    Hive.registerAdapter(ThemeConfigAdapter());
    Hive.registerAdapter(SyncStatusAdapter());
    Hive.registerAdapter(SyncFrequencyAdapter());
    Hive.registerAdapter(SyncConfigAdapter());

    _adaptersRegistered = true;
  }

  /// 首次启动时写入默认配置和预设模块清单。
  Future<void> _ensureDefaults() async {
    if (!_themeBox.containsKey(_configKey)) {
      await _themeBox.put(_configKey, ThemeConfig());
    }

    if (!_layoutBox.containsKey(_configKey)) {
      await _layoutBox.put(_configKey, LayoutConfig());
    }

    if (!_syncBox.containsKey(_configKey)) {
      await _syncBox.put(_configKey, SyncConfig());
    }

    if (_moduleDefBox.isEmpty) {
      final definitions = AppConstants.defaultModules.indexed.map((entry) {
        final (index, module) = entry;
        return ModuleDefinition(
          id: module.id,
          name: module.name,
          description: module.description,
          iconName: module.iconName,
          defaultEnabled: true,
        );
      }).toList();

      await _moduleDefBox.putAll({
        for (final def in definitions) def.id: def,
      });
    }

    if (_moduleStateBox.isEmpty) {
      final states = AppConstants.defaultModules.indexed.map((entry) {
        final (index, module) = entry;
        return ModuleState(
          moduleId: module.id,
          enabled: true,
          displayOrder: index,
        );
      }).toList();

      await _moduleStateBox.putAll({
        for (final state in states) state.moduleId: state,
      });
    }
  }

  @override
  Future<List<ModuleDefinition>> getModuleDefinitions() async {
    return _moduleDefBox.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  @override
  Future<void> setModuleDefinitions(List<ModuleDefinition> definitions) async {
    await _moduleDefBox.clear();
    await _moduleDefBox.putAll({
      for (final def in definitions) def.id: def,
    });
  }

  @override
  Future<List<ModuleState>> getModuleStates() async {
    return _moduleStateBox.values.toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  @override
  Future<void> setModuleStates(List<ModuleState> states) async {
    await _moduleStateBox.clear();
    await _moduleStateBox.putAll({
      for (final state in states) state.moduleId: state,
    });
  }

  @override
  Future<ThemeConfig?> getThemeConfig() async => _themeBox.get(_configKey);

  @override
  Future<void> setThemeConfig(ThemeConfig config) async {
    await _themeBox.put(_configKey, config);
  }

  @override
  Future<LayoutConfig?> getLayoutConfig() async => _layoutBox.get(_configKey);

  @override
  Future<void> setLayoutConfig(LayoutConfig config) async {
    await _layoutBox.put(_configKey, config);
  }

  @override
  Future<SyncConfig?> getSyncConfig() async => _syncBox.get(_configKey);

  @override
  Future<void> setSyncConfig(SyncConfig config) async {
    // 密码单独存储在 flutter_secure_storage，避免以任何形式落入 Hive。
    final configToStore = SyncConfig(
      enabled: config.enabled,
      serverUrl: config.serverUrl,
      username: config.username,
      passwordEncrypted: '',
      frequency: config.frequency,
      lastSyncTime: config.lastSyncTime,
      lastSyncStatus: config.lastSyncStatus,
    );
    await _syncBox.put(_configKey, configToStore);
  }

  @override
  Future<String?> getWebDavPassword() async {
    return _secureStorage.read(key: _webDavPasswordKey);
  }

  @override
  Future<void> setWebDavPassword(String password) async {
    await _secureStorage.write(key: _webDavPasswordKey, value: password);
  }

  @override
  Future<String?> getDeviceId() async {
    return _secureStorage.read(key: _deviceIdKey);
  }

  @override
  Future<void> setDeviceId(String deviceId) async {
    await _secureStorage.write(key: _deviceIdKey, value: deviceId);
  }

  @override
  Future<void> saveData(String key, Map<String, dynamic> data) async {
    final json = jsonEncode(data);
    await _moduleDataBox.put(key, json);
  }

  @override
  Future<Map<String, dynamic>?> loadData(String key) async {
    final json = _moduleDataBox.get(key);
    if (json == null || json.isEmpty) return null;
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
  }

  @override
  Future<void> deleteData(String key) async {
    await _moduleDataBox.delete(key);
  }

  @override
  Future<void> clearAll() async {
    await _themeBox.clear();
    await _layoutBox.clear();
    await _syncBox.clear();
    await _moduleDefBox.clear();
    await _moduleStateBox.clear();
    await _moduleDataBox.clear();
    await _secureStorage.delete(key: _webDavPasswordKey);
    await _secureStorage.delete(key: _deviceIdKey);
  }
}
