import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/models/sync_config.dart';
import 'package:ametoolbox/core/providers/sync_provider.dart';

/// 主页同步状态卡片。
///
/// 固定在模块卡片列表最底部，显示同步状态与时间。
class SyncStatusCard extends ConsumerWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);
    final config = syncService.config;

    final (icon, text, color) = _statusInfo(context, config, syncService.isSyncing);

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(text),
        trailing: config.lastSyncTime != null
            ? Text(_formatTime(config.lastSyncTime!))
            : null,
      ),
    );
  }

  (IconData, String, Color) _statusInfo(
    BuildContext context,
    SyncConfig config,
    bool isSyncing,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isSyncing) {
      return (
        Icons.sync,
        '同步中…',
        colorScheme.primary,
      );
    }

    switch (config.lastSyncStatus) {
      case SyncStatus.success:
        return (
          Icons.check_circle,
          '数据已同步',
          colorScheme.tertiary,
        );
      case SyncStatus.failed:
        return (
          Icons.error,
          '同步失败',
          colorScheme.error,
        );
      case SyncStatus.idle:
      default:
        return (
          Icons.cloud_off,
          '未配置同步',
          colorScheme.outline,
        );
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
