import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';

import 'core/platform/fake_device_info_provider.dart';
import 'core/storage/memory_storage_service.dart';
import 'features/calculator/calculator_module.dart';
import 'features/calculator/pages/calculator_page.dart';
import 'features/calculator/providers/calculator_config_provider.dart';

/// 多功能计算器模块的独立运行入口。
///
/// 该入口仅在隔离开发/测试时使用，不接入主项目底座的窗口管理、
/// 主题、同步等流程，因此启动轻量、编译快速。
///
/// 使用 [MemoryStorageService] 覆盖底座 [storageServiceProvider]，
/// 使模块级 Riverpod Provider 在独立环境中可用。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = MemoryStorageService();
  await storage.initialize();

  final module = CalculatorModule();
  await module.initialize(storage);

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        calculatorConfigProvider.overrideWith((ref) => module.configController!),
        deviceInfoProvider.overrideWithValue(const FakeDeviceInfoProvider()),
      ],
      child: _CalculatorStandaloneApp(module: module),
    ),
  );
}

class _CalculatorStandaloneApp extends StatelessWidget {
  final CalculatorModule module;

  const _CalculatorStandaloneApp({required this.module});

  @override
  Widget build(BuildContext context) {
    return InputModeScope(
      mode: InputMode.mouse,
      child: MaterialApp(
        title: '多功能计算器（独立开发环境）',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: CalculatorPage(module: module),
      ),
    );
  }
}
