import 'package:flutter/material.dart';

import 'package:ametoolbox/core/input/input_controller.dart';
import 'package:ametoolbox/core/input/input_mode_scope.dart';

/// 全局输入事件监听与 [InputModeScope] 注入。
///
/// 通过 [ListenableBuilder] 监听 [InputController]，把当前模式注入子树；
/// 通过 [Listener] 捕获 `PointerDown` 与 `PointerHover` 事件，驱动模式切换。
class InputDetector extends StatelessWidget {
  const InputDetector({
    super.key,
    required this.controller,
    required this.child,
  });

  final InputController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return InputModeScope(
          mode: controller.currentMode,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: controller.handlePointerDown,
            onPointerHover: controller.handlePointerHover,
            child: child,
          ),
        );
      },
    );
  }
}
