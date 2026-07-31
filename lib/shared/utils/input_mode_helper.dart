import 'package:flutter/material.dart';

import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';

/// 输入模式相关辅助方法。
///
/// 用于在自适应组件中快速判定当前模式并返回对应尺寸/边距。
class InputModeHelper {
  InputModeHelper._();

  /// 当前是否为触控模式。
  static bool isTouch(BuildContext context) {
    return InputModeScope.of(context) == InputMode.touch;
  }

  /// 当前是否为键鼠模式。
  static bool isMouse(BuildContext context) {
    return InputModeScope.of(context) == InputMode.mouse;
  }

  /// 触控模式下返回 48.0（MD3 最小触摸目标），键鼠模式下返回 [mouseSize]。
  static double tapTargetSize(BuildContext context, {double mouseSize = 40.0}) {
    return isTouch(context) ? 48.0 : mouseSize;
  }

  /// [ListTile.minVerticalPadding] 在触控模式下更大，键鼠模式下更紧凑。
  static double listTileMinVerticalPadding(BuildContext context) {
    return isTouch(context) ? 16.0 : 8.0;
  }
}
