import 'package:ametoolbox/core/models/input_mode.dart';

/// 运行平台分类。
enum AppPlatform {
  windows,
  macos,
  android,
  ios,
  harmonyos,
  unknown,
}

/// 平台信息抽象。
///
/// 提供运行平台的粗粒度分类信息，不暴露给 UI 层的实现细节。
abstract class PlatformInfo {
  /// 当前平台。
  AppPlatform get platform;

  /// 是否为桌面平台（Windows / macOS）。
  bool get isDesktop;

  /// 是否为移动平台（Android / iOS / HarmonyOS）。
  bool get isMobile;

  /// 当前平台的默认输入模式。
  InputMode get defaultInputMode;
}
