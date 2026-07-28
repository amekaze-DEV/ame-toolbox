import 'package:ametoolbox/core/platform/device_info_provider.dart';

/// Web 平台回退工厂。
Future<DeviceInfoProvider> createDeviceInfoProvider() async {
  throw UnsupportedError('Web platform is not supported by AMEToolbox.');
}
