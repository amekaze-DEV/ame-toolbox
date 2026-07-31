import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:ametoolbox/core/models/sync_config.dart';
import 'package:ametoolbox/core/modules/module_contract.dart';
import 'package:ametoolbox/core/platform/device_info_provider.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';
import 'package:ametoolbox/core/sync/conflict_resolver.dart';
import 'package:ametoolbox/core/sync/sync_exception.dart';
import 'package:ametoolbox/core/sync/webdav_client.dart';

/// WebDAV 同步服务状态管理。
///
/// 负责同步配置加载、自动同步定时器、手动/自动同步流程、冲突解决与状态反馈。
class SyncService extends ChangeNotifier {
  SyncService({
    required this.storage,
    required this.deviceInfo,
    this._registry = const [],
  });

  final StorageService storage;
  final DeviceInfoProvider deviceInfo;
  final List<ModuleContract> _registry;

  static const _syncMetaKey = 'webdav_sync_meta';

  SyncConfig _config = SyncConfig();
  bool _isSyncing = false;
  String? _errorMessage;
  double? _progress;
  Timer? _timer;

  SyncConfig get config => _config;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  double? get progress => _progress;

  /// 加载本地同步配置并启动自动同步定时器。
  Future<void> load() async {
    try {
      final stored = await storage.getSyncConfig();
      if (stored != null) {
        _config = stored;
        notifyListeners();
      }
    } catch (_) {
      // 首次启动或存储未就绪时使用默认值。
    }
    _restartTimer();
    _maybeTriggerStartupSync();
  }

  /// 更新同步配置并持久化。
  Future<void> updateConfig(SyncConfig config) async {
    _config = config;
    await _save();
    notifyListeners();
    _restartTimer();
  }

  /// 测试 WebDAV 连接。
  ///
  /// 连接成功时返回；失败时抛出 [SyncException]。
  Future<void> testConnection() async {
    final client = await _createClient();
    if (client == null) {
      throw const SyncException('请先配置服务器地址、用户名和密码');
    }
    try {
      await client.testConnection();
    } on SyncException {
      rethrow;
    } catch (e) {
      throw SyncException('连接失败: $e');
    }
  }

  /// 触发一次手动同步。
  Future<void> startSync() async {
    if (_isSyncing) return;
    if (!_config.enabled) {
      throw const SyncException('同步功能已关闭');
    }

    _isSyncing = true;
    _errorMessage = null;
    _progress = null;
    _config.lastSyncStatus = SyncStatus.syncing;
    notifyListeners();

    try {
      final client = await _createClient();
      if (client == null) {
        throw const SyncException('同步配置不完整');
      }
      await _performSync(client);
      _config.lastSyncStatus = SyncStatus.success;
      _config.lastSyncTime = DateTime.now();
      _errorMessage = null;
    } on SyncException catch (e) {
      _config.lastSyncStatus = SyncStatus.failed;
      _errorMessage = e.message;
    } catch (e) {
      _config.lastSyncStatus = SyncStatus.failed;
      _errorMessage = '同步失败: $e';
    } finally {
      _isSyncing = false;
      _progress = null;
      notifyListeners();
      await _save();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await storage.setSyncConfig(_config);
    } catch (_) {
      // 存储未就绪时忽略。
    }
  }

  Future<WebDavClient?> _createClient() async {
    final url = _config.serverUrl.trim();
    final username = _config.username.trim();
    if (url.isEmpty || username.isEmpty) return null;

    final password = await storage.getWebDavPassword();
    if (password == null || password.isEmpty) return null;

    return WebDavClient(
      baseUrl: url,
      username: username,
      password: password,
    );
  }

  Future<void> _performSync(WebDavClient client) async {
    final devicePath = '/${deviceInfo.deviceId}';
    await client.ensureDirectory(devicePath);

    final serverRaw = await client.readString('$devicePath/data.json');
    final serverModules = _parseServerModules(serverRaw);

    final meta = await _loadMeta();
    final resolver = ConflictResolver();
    final now = DateTime.now().toUtc();

    for (final module in _registry) {
      final id = module.definition.id;
      final localData = module.exportData();
      final localLastModified =
          _parseIso(meta[id] as String?)?.toUtc() ?? DateTime.utc(1970);
      final serverModule = serverModules[id];
      final serverData = serverModule?['data'] as Map<String, dynamic>?;
      final serverLastModified =
          _parseIso(serverModule?['lastModified'] as String?)?.toUtc();

      final resolution = resolver.resolve(
        localData: localData,
        localLastModified: localLastModified,
        serverData: serverData,
        serverLastModified: serverLastModified,
      );

      if (resolution.winner == ConflictWinner.server) {
        module.importData(resolution.data);
        meta[id] = resolution.lastModified.toUtc().toIso8601String();
      } else {
        // 本地胜出（含仅本地有数据的情况），使用本次同步时间作为本地版本时间戳。
        meta[id] = now.toUtc().toIso8601String();
      }

      if (resolution.archive != null) {
        await client.archive(
          moduleId: id,
          data: resolution.archive!,
          devicePath: devicePath,
        );
      }
    }

    // 使用当前模块数据与元数据时间戳构建最终上传数据。
    final finalModules = <String, Map<String, dynamic>>{};
    for (final module in _registry) {
      final id = module.definition.id;
      final data = module.exportData();
      final lastModified =
          _parseIso(meta[id] as String?)?.toUtc() ?? now;
      finalModules[id] = {
        'data': data,
        'lastModified': lastModified.toIso8601String(),
      };
    }

    final payload = {
      'version': 1,
      'lastSyncTime': now.toIso8601String(),
      'modules': finalModules,
    };

    await client.uploadJson(
      jsonEncode(payload),
      '$devicePath/data.json',
      onProgress: (count, total) => _updateProgress(count, total),
    );
    await _saveMeta(meta);
  }

  void _updateProgress(int count, int total) {
    if (total <= 0) return;
    _progress = count / total;
    notifyListeners();
  }

  Map<String, Map<String, dynamic>> _parseServerModules(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final modules = decoded['modules'] as Map<String, dynamic>?;
      if (modules == null) return {};
      return modules.map((key, value) {
        final module = value as Map<String, dynamic>;
        return MapEntry<String, Map<String, dynamic>>(key, module);
      });
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadMeta() async {
    final data = await storage.loadData(_syncMetaKey);
    return data ?? {};
  }

  Future<void> _saveMeta(Map<String, dynamic> meta) async {
    await storage.saveData(_syncMetaKey, meta);
  }

  DateTime? _parseIso(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = null;
    if (!_config.enabled) return;

    final interval = _frequencyToInterval(_config.frequency);
    if (interval == null) return;

    _timer = Timer.periodic(interval, (_) => unawaited(startSync()));
  }

  void _maybeTriggerStartupSync() {
    if (!_config.enabled) return;

    final interval = _frequencyToInterval(_config.frequency);
    if (interval == null) return;

    final last = _config.lastSyncTime;
    if (last == null || DateTime.now().difference(last) > interval) {
      unawaited(startSync());
    }
  }

  Duration? _frequencyToInterval(SyncFrequency frequency) {
    return switch (frequency) {
      SyncFrequency.manual => null,
      SyncFrequency.fiveMin => const Duration(minutes: 5),
      SyncFrequency.fifteenMin => const Duration(minutes: 15),
      SyncFrequency.sixtyMin => const Duration(minutes: 60),
    };
  }
}
