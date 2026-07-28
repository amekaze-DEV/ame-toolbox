import 'package:flutter/material.dart';

import 'package:ametoolbox/core/models/input_mode.dart';

/// 向子树注入当前 [InputMode] 的 InheritedWidget。
class InputModeScope extends InheritedWidget {
  const InputModeScope({
    super.key,
    required this.mode,
    required super.child,
  });

  /// 当前输入模式。
  final InputMode mode;

  /// 从 [BuildContext] 获取最近的 [InputModeScope]，触发重建。
  static InputMode of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<InputModeScope>();
    assert(scope != null, 'InputModeScope not found in widget tree');
    return scope!.mode;
  }

  /// 获取当前模式，若未找到则返回 null（不触发重建）。
  static InputMode? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InputModeScope>()?.mode;
  }

  @override
  bool updateShouldNotify(InputModeScope oldWidget) => mode != oldWidget.mode;
}
