import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:ametoolbox/core/constants.dart';
import 'package:ametoolbox/core/platform/android_device_info.dart';
import 'package:ametoolbox/core/platform/device_info_provider.dart';
import 'package:ametoolbox/core/platform/ios_device_info.dart';
import 'package:ametoolbox/core/platform/macos_device_info.dart';
import 'package:ametoolbox/core/platform/ohos_device_info.dart';
import 'package:ametoolbox/core/platform/windows_device_info.dart';

const _deviceIdKey = 'ame_device_id';

/// 创建当前平台的 [DeviceInfoProvider] 实例。
///
/// 该方法在 dart:io 可用时编译，Web 平台走回退实现。
Future<DeviceInfoProvider> createDeviceInfoProvider() async {
  final secureStorage = const FlutterSecureStorage();
  String? deviceId = await secureStorage.read(key: _deviceIdKey);
  if (deviceId == null || deviceId.isEmpty) {
    deviceId = _generateUuid();
    await secureStorage.write(key: _deviceIdKey, value: deviceId);
  }

  final packageInfo = await PackageInfo.fromPlatform();
  final deviceInfoPlugin = DeviceInfoPlugin();

  if (Platform.isWindows) {
    // device_info_plus 在部分 Windows 版本获取系统信息时会抛出异常，
    // 使用 Platform.localHostname 作为设备型号回退。
    String deviceModel;
    try {
      final windowsInfo = await deviceInfoPlugin.windowsInfo;
      deviceModel = windowsInfo.computerName;
    } catch (_) {
      deviceModel = Platform.localHostname;
    }
    final pixelRatio =
        PlatformDispatcher.instance.views.firstOrNull?.devicePixelRatio ?? 1.0;
    return WindowsDeviceInfoProvider(
      deviceId: deviceId,
      osName: 'Windows',
      osVersion: Platform.operatingSystemVersion,
      deviceModel: deviceModel,
      appVersion: packageInfo.version,
      appBuildNumber: packageInfo.buildNumber,
      physicalDpi: pixelRatio * AppConstants.desktopBaseDpi,
      physicalScreenSize: null,
      inputCapability: DeviceInputCapability.hybrid,
    );
  }

  if (Platform.isMacOS) {
    final macInfo = await deviceInfoPlugin.macOsInfo;
    final pixelRatio =
        PlatformDispatcher.instance.views.firstOrNull?.devicePixelRatio ?? 1.0;
    return MacosDeviceInfoProvider(
      deviceId: deviceId,
      osName: 'macOS',
      osVersion: Platform.operatingSystemVersion,
      deviceModel: macInfo.model,
      appVersion: packageInfo.version,
      appBuildNumber: packageInfo.buildNumber,
      physicalDpi: pixelRatio * AppConstants.desktopBaseDpi,
      physicalScreenSize: null,
      inputCapability: DeviceInputCapability.mouseOnly,
    );
  }

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfoPlugin.androidInfo;
    // device_info_plus 10.x 不再暴露 displayMetrics；使用 Android 基准 DPI。
    const physicalDpi = 160.0;
    return AndroidDeviceInfoProvider(
      deviceId: deviceId,
      osName: 'Android',
      osVersion: androidInfo.version.release,
      deviceModel: '${androidInfo.manufacturer} ${androidInfo.model}',
      appVersion: packageInfo.version,
      appBuildNumber: packageInfo.buildNumber,
      physicalDpi: physicalDpi,
      physicalScreenSize: null,
      inputCapability: DeviceInputCapability.touchOnly,
    );
  }

  if (Platform.isIOS) {
    final iosInfo = await deviceInfoPlugin.iosInfo;
    final pixelRatio =
        PlatformDispatcher.instance.views.firstOrNull?.devicePixelRatio ?? 1.0;
    return IosDeviceInfoProvider(
      deviceId: deviceId,
      osName: iosInfo.systemName,
      osVersion: iosInfo.systemVersion,
      deviceModel: iosInfo.model,
      appVersion: packageInfo.version,
      appBuildNumber: packageInfo.buildNumber,
      physicalDpi: pixelRatio * AppConstants.desktopBaseDpi,
      physicalScreenSize: null,
      inputCapability: DeviceInputCapability.touchOnly,
    );
  }

  // HarmonyOS 未在 dart:io 中识别，按未知平台预留 Phase 4 实现。
  final pixelRatio =
      PlatformDispatcher.instance.views.firstOrNull?.devicePixelRatio ?? 1.0;
  return OhosDeviceInfoProvider(
    deviceId: deviceId,
    osName: 'HarmonyOS',
    osVersion: Platform.operatingSystemVersion,
    deviceModel: Platform.localHostname,
    appVersion: packageInfo.version,
    appBuildNumber: packageInfo.buildNumber,
    physicalDpi: pixelRatio * AppConstants.desktopBaseDpi,
    physicalScreenSize: null,
    inputCapability: DeviceInputCapability.touchOnly,
  );
}

String _generateUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;
  final chars = bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .toList(growable: false);
  return '${chars[0]}${chars[1]}${chars[2]}${chars[3]}-'
      '${chars[4]}${chars[5]}-'
      '${chars[6]}${chars[7]}-'
      '${chars[8]}${chars[9]}-'
      '${chars[10]}${chars[11]}${chars[12]}${chars[13]}${chars[14]}${chars[15]}';
}
