import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:ametoolbox/core/theme/theme_controller.dart';

/// 主题状态管理。
final themeControllerProvider = ChangeNotifierProvider<ThemeController>(
  (ref) {
    final storage = ref.watch(storageServiceProvider);
    return ThemeController(storage: storage);
  },
);
