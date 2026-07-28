import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/platform/device_info_provider.dart';
import 'package:ametoolbox/core/platform/platform_info.dart';
import 'package:ametoolbox/core/platform/platform_info_impl.dart';

/// 注入当前平台信息。
final platformInfoProvider = Provider<PlatformInfo>(
  (ref) => PlatformInfoImpl(),
);

/// 注入当前设备信息。
///
/// 该 Provider 在 [main] 中通过 overrideWithValue 注入异步初始化后的实例。
final deviceInfoProvider = Provider<DeviceInfoProvider>(
  (ref) => throw UnimplementedError(
    'deviceInfoProvider must be overridden in main()',
  ),
);
