import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:ametoolbox/app.dart';
import 'package:ametoolbox/core/constants.dart';
import 'package:ametoolbox/core/input/input_controller.dart';
import 'package:ametoolbox/core/layout/layout_controller.dart';
import 'package:ametoolbox/core/modules/module_controller.dart';
import 'package:ametoolbox/core/modules/module_registry.dart';
import 'package:ametoolbox/core/platform/device_info_provider_factory.dart';
import 'package:ametoolbox/core/notifications/local_notification_service.dart';
import 'package:ametoolbox/core/platform/platform_info_impl.dart';
import 'package:ametoolbox/core/providers/input_provider.dart';
import 'package:ametoolbox/core/providers/layout_provider.dart';
import 'package:ametoolbox/core/providers/module_provider.dart';
import 'package:ametoolbox/core/providers/notification_provider.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:ametoolbox/core/providers/sync_provider.dart';
import 'package:ametoolbox/core/providers/theme_provider.dart';
import 'package:ametoolbox/core/storage/hive_storage.dart';
import 'package:ametoolbox/core/sync/sync_service.dart';
import 'package:ametoolbox/core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowManager.instance.ensureInitialized();
  await WindowManager.instance.setMinimumSize(
    const Size(AppConstants.windowMinWidth, AppConstants.windowMinHeight),
  );

  final platformInfo = PlatformInfoImpl();
  final storage = HiveStorage();
  await storage.initialize();
  final deviceInfo = await createDeviceInfoProvider();

  final registry = ModuleRegistry.registerAll();
  final moduleController = ModuleController(
    storage: storage,
    registry: registry,
  );

  final themeController = ThemeController(storage: storage);
  final layoutController = LayoutController(
    storage: storage,
    platformInfo: platformInfo,
    deviceInfo: deviceInfo,
  );
  final inputController = InputController(platformInfo: platformInfo);
  final syncService = SyncService(
    storage: storage,
    deviceInfo: deviceInfo,
    registry: registry,
  );
  final notificationService = LocalNotificationService();
  await notificationService.initialize();

  // 先初始化所有已注册模块，再加载同步服务。
  //
  // 同步服务加载时可能立即触发一次启动同步，而同步会调用模块的
  // `exportData()`；若模块尚未初始化，导出会拿到默认 / 空数据，
  // 存在覆盖服务端数据的风险。
  for (final module in registry) {
    await module.initialize(storage);
  }

  await Future.wait([
    themeController.load(),
    layoutController.load(),
    syncService.load(),
    moduleController.load(),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        platformInfoProvider.overrideWithValue(platformInfo),
        storageServiceProvider.overrideWithValue(storage),
        deviceInfoProvider.overrideWithValue(deviceInfo),
        themeControllerProvider.overrideWith((ref) => themeController),
        layoutControllerProvider.overrideWith((ref) => layoutController),
        inputControllerProvider.overrideWith((ref) => inputController),
        syncServiceProvider.overrideWith((ref) => syncService),
        notificationServiceProvider.overrideWithValue(notificationService),
        moduleControllerProvider.overrideWith((ref) => moduleController),
      ],
      child: const App(),
    ),
  );
}
