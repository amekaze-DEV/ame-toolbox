import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/platform/platform_info.dart';

/// 自动检测触控/键鼠输入模式并管理当前模式状态。
///
/// - 首次输入事件前使用 [PlatformInfo.defaultInputMode] 作为初始模式。
/// - [PointerDownEvent] 根据 `kind` 判定为触控或键鼠。
/// - [PointerHoverEvent] 只可能来自鼠标，直接切换到键鼠模式。
/// - 模式切换带 300ms 防抖，避免触屏笔记本上频繁来回切换。
class InputController extends ChangeNotifier {
  InputController({required PlatformInfo platformInfo})
      : _currentMode = platformInfo.defaultInputMode;

  InputMode _currentMode;
  DateTime _lastSwitchTime = DateTime.fromMillisecondsSinceEpoch(0);

  static const _switchDebounce = Duration(milliseconds: 300);

  InputMode get currentMode => _currentMode;

  /// 处理 [PointerDownEvent]，根据触点类型切换模式。
  void handlePointerDown(PointerDownEvent event) {
    final newMode = event.kind == PointerDeviceKind.touch
        ? InputMode.touch
        : InputMode.mouse;
    _switchTo(newMode);
  }

  /// 处理 [PointerHoverEvent]，hover 仅可能来自鼠标。
  void handlePointerHover(PointerHoverEvent event) {
    _switchTo(InputMode.mouse);
  }

  void _switchTo(InputMode newMode) {
    if (newMode == _currentMode) return;

    final now = DateTime.now();
    if (now.difference(_lastSwitchTime) < _switchDebounce) return;

    _currentMode = newMode;
    _lastSwitchTime = now;
    notifyListeners();
  }
}
