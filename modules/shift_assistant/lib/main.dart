import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/layout/layout_controller.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/platform/platform_info_impl.dart';
import 'package:ametoolbox/core/providers/layout_provider.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';

import 'core/platform/fake_device_info_provider.dart';
import 'core/storage/memory_storage_service.dart';
import 'features/shift_assistant/data/shift_config_repository.dart';
import 'features/shift_assistant/providers/shift_config_provider.dart';
import 'features/shift_assistant/shift_assistant_module.dart';
import 'features/shift_assistant/pages/shift_assistant_page.dart';

/// 倒班助手模块的独立运行入口。
///
/// 该入口仅在隔离开发/测试时使用，不接入主项目底座的窗口管理、
/// 主题、同步等流程，因此启动轻量、编译快速。
///
/// 使用 [MemoryStorageService] 覆盖底座 [storageServiceProvider]，
/// 使模块级 Riverpod Provider 在独立环境中可用。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);

  final storage = MemoryStorageService();
  await storage.initialize();

  final module = ShiftAssistantModule();
  await module.initialize(storage);

  final repository = ShiftConfigRepository(storage: storage);

  final platformInfo = PlatformInfoImpl();
  const deviceInfo = FakeDeviceInfoProvider();
  final layoutController = LayoutController(
    storage: storage,
    platformInfo: platformInfo,
    deviceInfo: deviceInfo,
  );

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        shiftConfigRepositoryProvider.overrideWithValue(repository),
        deviceInfoProvider.overrideWithValue(deviceInfo),
        layoutControllerProvider.overrideWith((ref) => layoutController),
      ],
      child: _ShiftAssistantStandaloneApp(module: module),
    ),
  );
}

class _ShiftAssistantStandaloneApp extends StatelessWidget {
  final ShiftAssistantModule module;

  const _ShiftAssistantStandaloneApp({required this.module});

  @override
  Widget build(BuildContext context) {
    return InputModeScope(
      mode: InputMode.mouse,
      child: MaterialApp(
        title: '倒班助手（独立开发环境）',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const ShiftAssistantPage(),
      ),
    );
  }
}
