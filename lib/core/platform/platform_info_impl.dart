import 'dart:io';

import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/platform/platform_info.dart';

/// [PlatformInfo] 的 dart:io 实现。
class PlatformInfoImpl implements PlatformInfo {
  @override
  AppPlatform get platform {
    if (Platform.isWindows) return AppPlatform.windows;
    if (Platform.isMacOS) return AppPlatform.macos;
    if (Platform.isAndroid) return AppPlatform.android;
    if (Platform.isIOS) return AppPlatform.ios;
    // HarmonyOS 无法通过 dart:io 直接判断，Phase 4 再补充。
    return AppPlatform.unknown;
  }

  @override
  bool get isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  bool get isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  InputMode get defaultInputMode => isDesktop ? InputMode.mouse : InputMode.touch;
}
