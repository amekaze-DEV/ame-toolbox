import 'package:hive/hive.dart';

part 'sync_config.g.dart';

/// 同步状态。
@HiveType(typeId: 6)
enum SyncStatus {
  @HiveField(0)
  idle,

  @HiveField(1)
  syncing,

  @HiveField(2)
  success,

  @HiveField(3)
  failed,
}

/// 同步频率。
@HiveType(typeId: 7)
enum SyncFrequency {
  @HiveField(0)
  manual,

  @HiveField(1)
  fiveMin,

  @HiveField(2)
  fifteenMin,

  @HiveField(3)
  sixtyMin,
}

/// 同步配置数据。
@HiveType(typeId: 8)
class SyncConfig {
  SyncConfig({
    this.enabled = false,
    this.serverUrl = '',
    this.username = '',
    this.passwordEncrypted = '',
    this.frequency = SyncFrequency.fiveMin,
    this.lastSyncTime,
    this.lastSyncStatus = SyncStatus.idle,
  });

  @HiveField(0, defaultValue: false)
  bool enabled;

  @HiveField(1, defaultValue: '')
  String serverUrl;

  @HiveField(2, defaultValue: '')
  String username;

  @HiveField(3, defaultValue: '')
  String passwordEncrypted;

  @HiveField(4, defaultValue: SyncFrequency.fiveMin)
  SyncFrequency frequency;

  @HiveField(5)
  DateTime? lastSyncTime;

  @HiveField(6, defaultValue: SyncStatus.idle)
  SyncStatus lastSyncStatus;
}
