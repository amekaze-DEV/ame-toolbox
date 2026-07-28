/// 设备支持的输入能力。
enum DeviceInputCapability {
  /// 仅触控（手机、平板无键盘）。
  touchOnly,

  /// 仅键鼠（传统桌面）。
  mouseOnly,

  /// 混合（触屏笔记本、平板+键盘套）。
  hybrid,
}

/// 系统与设备信息统一抽象。
///
/// UI 层通过此接口获取设备/系统信息，实现类按平台分别定义，
/// 不暴露给 UI 层。
abstract class DeviceInfoProvider {
  /// 设备唯一标识（用于 WebDAV 同步路径），首次启动生成后持久化。
  String get deviceId;

  /// 操作系统名称（如 "Windows 11", "Android 14"）。
  String get osName;

  /// 操作系统版本号。
  String get osVersion;

  /// 设备型号/名称（如 "Desktop-ABC123", "Pixel 8"）。
  String get deviceModel;

  /// 应用版本号（如 "1.0.0"）。
  String get appVersion;

  /// 应用构建号。
  String get appBuildNumber;

  /// 屏幕物理 DPI（用于自动 DPI 缩放计算）。
  double get physicalDpi;

  /// 屏幕物理对角线尺寸（英寸），无法获取时返回 null。
  double? get physicalScreenSize;

  /// 设备支持的输入方式。
  DeviceInputCapability get inputCapability;
}
