import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/input/input_controller.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';

/// 输入模式状态管理。
final inputControllerProvider = ChangeNotifierProvider<InputController>(
  (ref) {
    final platformInfo = ref.watch(platformInfoProvider);
    return InputController(platformInfo: platformInfo);
  },
);
