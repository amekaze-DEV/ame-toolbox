import 'package:ametoolbox/core/platform/device_info_provider.dart';

/// 简化 DeviceInfoProvider（仅用于单元 / Widget 测试）。
///
/// 固定返回桌面端信息，规避 device_info_plus 插件在测试环境不可用的问题。
class FakeDeviceInfoProvider implements DeviceInfoProvider {
  @override
  String get deviceId => 'sticky_notes_test_device';

  @override
  String get osName => 'Windows';

  @override
  String get osVersion => '11';

  @override
  String get deviceModel => 'TestDesktop';

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
