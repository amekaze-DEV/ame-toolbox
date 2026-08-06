import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shift_config_repository.dart';
import 'shift_config_controller.dart';

/// 注入 [ShiftConfigRepository]。
final shiftConfigRepositoryProvider = Provider<ShiftConfigRepository>((ref) {
  throw UnimplementedError(
    'ShiftConfigRepository 应在模块初始化时通过 ProviderScope.overrideWithValue 注入',
  );
});

/// 倒班助手配置状态。
final shiftConfigProvider = ChangeNotifierProvider<ShiftConfigController>(
  (ref) {
    final repository = ref.watch(shiftConfigRepositoryProvider);
    return ShiftConfigController(repository: repository);
  },
);
