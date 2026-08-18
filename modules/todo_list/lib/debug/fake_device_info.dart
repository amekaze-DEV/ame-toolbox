import 'package:ametoolbox/core/platform/device_info_provider.dart';

/// 简化 DeviceInfoProvider（临时调试用）。
///
/// 返回固定 DPI/内存值，规避项目已知的 device_info_plus
/// 在部分 Windows 版本取内存抛异常问题。
class FakeDeviceInfoProvider implements DeviceInfoProvider {
  @override
  String get deviceId => 'fake-device-id';

  @override
  String get osName => 'Windows 11';

  @override
  String get osVersion => '10.0';

  @override
  String get deviceModel => 'Debug-PC';

  @override
  String get appVersion => '1.0.0';

  @override
  String get appBuildNumber => '1';

  @override
  double get physicalDpi => 96.0;

  @override
  double? get physicalScreenSize => 15.6;

  @override
  DeviceInputCapability get inputCapability =>
      DeviceInputCapability.mouseOnly;
}