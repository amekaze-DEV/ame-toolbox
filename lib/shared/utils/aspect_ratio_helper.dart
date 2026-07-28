import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:ametoolbox/core/models/layout_mode.dart';

/// 宽高比与布局模式计算工具。
///
/// 提供与 [LayoutController] 一致的纯函数计算能力，供需要在 Build 上下文中
/// 快速判断布局模式的 Widget 使用。
class AspectRatioHelper {
  const AspectRatioHelper._();

  /// 计算给定尺寸的宽高比。
  ///
  /// 当高度为 0 时返回 0，避免除零异常。
  static double of(Size size) {
    if (size.height == 0) return 0;
    return size.width / size.height;
  }

  /// 根据宽高比与断点值判定布局模式。
  static LayoutMode mode(double aspectRatio, double breakpoint) {
    if (aspectRatio >= breakpoint) return LayoutMode.landscape;
    return LayoutMode.portrait;
  }

  /// 计算屏幕短边长度（逻辑像素）。
  static double shortestSide(Size size) {
    return math.min(size.width, size.height);
  }
}
