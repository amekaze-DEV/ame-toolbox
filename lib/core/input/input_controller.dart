import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:ametoolbox/core/constants.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/platform/platform_info.dart';

/// 自动检测触控/键鼠输入模式。
class InputController extends ChangeNotifier {
  InputController({required PlatformInfo platformInfo})
      : _mode = platformInfo.defaultInputMode;

  InputMode _mode;
  InputMode get mode => _mode;

  Timer? _debounceTimer;

  /// 处理 Pointer 事件并判定输入模式。
  void onPointerEvent(PointerEvent event) {
    final InputMode? newMode;
    if (event is PointerHoverEvent) {
      newMode = InputMode.mouse;
    } else if (event is PointerDownEvent) {
      newMode = event.kind == PointerDeviceKind.touch
          ? InputMode.touch
          : InputMode.mouse;
    } else {
      newMode = null;
    }

    if (newMode == null || newMode == _mode) {
      _debounceTimer?.cancel();
      return;
    }

    final modeToSet = newMode;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: AppConstants.inputModeDebounceMs),
      () {
        _mode = modeToSet;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
