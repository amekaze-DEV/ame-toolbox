import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:ametoolbox/core/sync/sync_service.dart';

/// WebDAV 同步服务状态管理。
final syncServiceProvider = ChangeNotifierProvider<SyncService>(
  (ref) {
    final storage = ref.watch(storageServiceProvider);
    final deviceInfo = ref.watch(deviceInfoProvider);
    return SyncService(storage: storage, deviceInfo: deviceInfo);
  },
);
