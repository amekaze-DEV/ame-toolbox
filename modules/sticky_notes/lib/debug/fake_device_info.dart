import 'package:ametoolbox/core/platform/device_info_provider.dart';

///【临时】简化 DeviceInfoProvider（固定值，合并主线后删除）。
///
/// 规避 device_info_plus 在部分 Windows 版本获取系统内存时抛异常的问题。
/// physicalDpi 取 96 使桌面端 DPI 缩放为 1.0；
/// physicalScreenSize 取桌面显示器尺寸，使断点策略走桌面分支（1.20）。
class FakeDeviceInfoProvider implements DeviceInfoProvider {
  @override
  String get deviceId => 'sticky_notes_debug_device';

  @override
  String get osName => 'Windows';

  @override
  String get osVersion => '11';

  @override
  String get deviceModel => 'DebugDesktop';

  @override
  String get appVersion => '0.1.0';

  @override
  String get appBuildNumber => '1';

  @override
  double get physicalDpi => 96.0;

  @override
  double? get physicalScreenSize => 24.0;

  @override
  DeviceInputCapability get inputCapability => DeviceInputCapability.hybrid;
}
