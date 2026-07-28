import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:ametoolbox/core/constants.dart';
import 'package:ametoolbox/core/models/layout_config.dart';
import 'package:ametoolbox/core/models/layout_mode.dart';
import 'package:ametoolbox/core/platform/device_info_provider.dart';
import 'package:ametoolbox/core/platform/platform_info.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

/// 布局状态管理（横竖屏模式、断点、DPI 缩放）。
class LayoutController extends ChangeNotifier with WidgetsBindingObserver {
  LayoutController({
    required this._storage,
    required this._platformInfo,
    required this._deviceInfo,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _updateFromView(PlatformDispatcher.instance.views.firstOrNull);
  }

  final StorageService _storage;
  final PlatformInfo _platformInfo;
  final DeviceInfoProvider _deviceInfo;

  LayoutConfig _config = LayoutConfig();
  Size _screenSize = Size.zero;

  LayoutConfig get config => _config;
  Size get screenSize => _screenSize;

  /// 生效中的断点值。
  double get effectiveBreakpoint {
    if (_config.autoBreakpoint) {
      if (_platformInfo.isDesktop) return AppConstants.autoBreakpointDesktop;
      final shortSide = math.min(_screenSize.width, _screenSize.height);
      if (shortSide < AppConstants.phoneMaxShortSide) {
        return AppConstants.autoBreakpointPhone;
      }
      if (shortSide < AppConstants.tabletMaxShortSide) {
        return AppConstants.autoBreakpointTablet;
      }
      return AppConstants.autoBreakpointDesktop;
    }
    return _config.breakpoint.clamp(
      AppConstants.minBreakpoint,
      AppConstants.maxBreakpoint,
    );
  }

  /// 生效中的 DPI 缩放因子。
  double get effectiveDpiScale {
    if (_config.autoDpi) {
      if (_platformInfo.isMobile) return 1.0;
      return (_deviceInfo.physicalDpi / AppConstants.desktopBaseDpi)
          .clamp(AppConstants.minDpiScale, AppConstants.maxDpiScale);
    }
    return _config.dpiScale.clamp(
      AppConstants.minDpiScale,
      AppConstants.maxDpiScale,
    );
  }

  /// 当前布局模式。
  LayoutMode get layoutMode {
    if (_screenSize.width <= 0 || _screenSize.height <= 0) {
      return LayoutMode.portrait;
    }
    return _screenSize.width / _screenSize.height >= effectiveBreakpoint
        ? LayoutMode.landscape
        : LayoutMode.portrait;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _updateFromView(PlatformDispatcher.instance.views.firstOrNull);
  }

  Future<void> load() async {
    try {
      final stored = await _storage.getLayoutConfig();
      if (stored != null) {
        _config = stored;
        notifyListeners();
      }
    } catch (_) {
      // 首次启动或存储未就绪时使用默认值。
    }
  }

  void _updateFromView(FlutterView? view) {
    if (view == null) return;
    final size = view.physicalSize / view.devicePixelRatio;
    if (_screenSize == size) return;
    _screenSize = size;
    notifyListeners();
  }

  Future<void> setAutoBreakpoint(bool value) async {
    if (_config.autoBreakpoint == value) return;
    _config.autoBreakpoint = value;
    await _save();
    notifyListeners();
  }

  Future<void> setBreakpoint(double value) async {
    final clamped = value.clamp(
      AppConstants.minBreakpoint,
      AppConstants.maxBreakpoint,
    );
    if ((_config.breakpoint - clamped).abs() < 0.001) return;
    _config.breakpoint = clamped;
    await _save();
    notifyListeners();
  }

  Future<void> setAutoDpi(bool value) async {
    if (_config.autoDpi == value) return;
    _config.autoDpi = value;
    await _save();
    notifyListeners();
  }

  Future<void> setDpiScale(double value) async {
    final clamped = value.clamp(
      AppConstants.minDpiScale,
      AppConstants.maxDpiScale,
    );
    if ((_config.dpiScale - clamped).abs() < 0.01) return;
    _config.dpiScale = clamped;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      await _storage.setLayoutConfig(_config);
    } catch (_) {
      // 存储未就绪时忽略。
    }
  }
}
