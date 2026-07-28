import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/modules/module_controller.dart';
import 'package:ametoolbox/core/modules/module_registry.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';

/// 模块管理状态管理。
final moduleControllerProvider = ChangeNotifierProvider<ModuleController>(
  (ref) {
    final storage = ref.watch(storageServiceProvider);
    return ModuleController(
      storage: storage,
      registry: ModuleRegistry.registerAll(),
    );
  },
);
