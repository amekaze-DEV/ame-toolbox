import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/layout/layout_controller.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';

/// 布局状态管理。
final layoutControllerProvider = ChangeNotifierProvider<LayoutController>(
  (ref) {
    final storage = ref.watch(storageServiceProvider);
    final platformInfo = ref.watch(platformInfoProvider);
    final deviceInfo = ref.watch(deviceInfoProvider);
    return LayoutController(
      storage: storage,
      platformInfo: platformInfo,
      deviceInfo: deviceInfo,
    );
  },
);
