import 'package:ametoolbox/core/platform/device_info_provider.dart';

/// HarmonyOS 平台 [DeviceInfoProvider] 预留实现。
class OhosDeviceInfoProvider implements DeviceInfoProvider {
  const OhosDeviceInfoProvider({
    required this.deviceId,
    required this.osName,
    required this.osVersion,
    required this.deviceModel,
    required this.appVersion,
    required this.appBuildNumber,
    required this.physicalDpi,
    this.physicalScreenSize,
    this.inputCapability = DeviceInputCapability.touchOnly,
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
