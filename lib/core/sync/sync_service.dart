import 'package:flutter/material.dart';

import 'package:ametoolbox/core/models/sync_config.dart';
import 'package:ametoolbox/core/platform/device_info_provider.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

/// WebDAV 同步服务状态管理。
class SyncService extends ChangeNotifier {
  SyncService({
    required this._storage,
    required this._deviceInfo,
  });

  // ignore: unused_field
  final DeviceInfoProvider _deviceInfo;

  final StorageService _storage;

  SyncConfig _config = SyncConfig();
  bool _isSyncing = false;

  SyncConfig get config => _config;
  bool get isSyncing => _isSyncing;

  Future<void> load() async {
    try {
      final stored = await _storage.getSyncConfig();
      if (stored != null) {
        _config = stored;
        notifyListeners();
      }
    } catch (_) {
      // 首次启动或存储未就绪时使用默认值。
    }
  }

  Future<void> updateConfig(SyncConfig config) async {
    _config = config;
    await _save();
    notifyListeners();
  }

  Future<void> testConnection() async {
    // TODO: TASK-07 实现 WebDAV 连接测试。
    notifyListeners();
  }

  Future<void> startSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _config.lastSyncStatus = SyncStatus.syncing;
    notifyListeners();

    try {
      // TODO: TASK-07 实现 WebDAV 同步流程。
      await Future<void>.delayed(const Duration(seconds: 1));
      _config.lastSyncStatus = SyncStatus.success;
      _config.lastSyncTime = DateTime.now();
    } catch (_) {
      _config.lastSyncStatus = SyncStatus.failed;
    } finally {
      _isSyncing = false;
      notifyListeners();
      await _save();
    }
  }

  Future<void> _save() async {
    try {
      await _storage.setSyncConfig(_config);
    } catch (_) {
      // 存储未就绪时忽略。
    }
  }
}
