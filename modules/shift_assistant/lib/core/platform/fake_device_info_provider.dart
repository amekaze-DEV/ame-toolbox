import 'package:ametoolbox/core/platform/device_info_provider.dart';

/// 独立开发/测试环境使用的假设备信息提供器。
///
/// 避免在模块独立运行时依赖平台原生 API，确保布局控制器可正常初始化。
class FakeDeviceInfoProvider implements DeviceInfoProvider {
  const FakeDeviceInfoProvider();

  @override
  String get deviceId => 'shift-assistant-dev';

  @override
  String get osName => 'Standalone';

  @override
  String get osVersion => '1.0';

  @override
  String get deviceModel => 'ShiftAssistantDev';

  @override
  String get appVersion => '1.0.0';

  @override
  String get appBuildNumber => '1';

  @override
  double get physicalDpi => 96;

  @override
  double? get physicalScreenSize => null;

  @override
  DeviceInputCapability get inputCapability => DeviceInputCapability.mouseOnly;
}
