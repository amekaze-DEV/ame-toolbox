import 'package:ametoolbox/core/platform/device_info_provider.dart';

/// Windows 平台 [DeviceInfoProvider] 实现。
class WindowsDeviceInfoProvider implements DeviceInfoProvider {
  const WindowsDeviceInfoProvider({
    required this.deviceId,
    required this.osName,
    required this.osVersion,
    required this.deviceModel,
    required this.appVersion,
    required this.appBuildNumber,
    required this.physicalDpi,
    this.physicalScreenSize,
    this.inputCapability = DeviceInputCapability.hybrid,
  });

  @override
  final String deviceId;

  @override
  final String osName;

  @override
  final String osVersion;

  @override
  final String deviceModel;

  @override
  final String appVersion;

  @override
  final String appBuildNumber;

  @override
  final double physicalDpi;

  @override
  final double? physicalScreenSize;

  @override
  final DeviceInputCapability inputCapability;
}
