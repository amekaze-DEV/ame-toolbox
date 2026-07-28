import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/storage/storage_service.dart';

/// 注入本地持久化存储服务。
///
/// 该 Provider 在 [main] 中通过 overrideWithValue 注入初始化后的实例。
final storageServiceProvider = Provider<StorageService>(
  (ref) => throw UnimplementedError(
    'storageServiceProvider must be overridden in main()',
  ),
);
