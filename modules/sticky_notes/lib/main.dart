import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/input/input_controller.dart';
import 'package:ametoolbox/core/input/input_detector.dart';
import 'package:ametoolbox/core/layout/layout_controller.dart';
import 'package:ametoolbox/core/models/theme_config.dart' as app_theme;
import 'package:ametoolbox/core/platform/platform_info_impl.dart';
import 'package:ametoolbox/core/providers/input_provider.dart';
import 'package:ametoolbox/core/providers/layout_provider.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:ametoolbox/core/providers/theme_provider.dart';
import 'package:ametoolbox/core/theme/md3_color_scheme.dart';
import 'package:ametoolbox/core/theme/theme_controller.dart';

import 'debug/fake_device_info.dart';
import 'debug/memory_storage_service.dart';
import 'features/sticky_notes/sticky_notes_module.dart';

///【临时】便签模块独立运行入口（合并主线后删除）。
///
/// 轻量临时底座：内存 Storage + 简化 DeviceInfo，
/// 主题与横竖屏断点逻辑与主线一致。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = MemoryStorageService();
  await storage.initialize();

  final platformInfo = PlatformInfoImpl();
  final deviceInfo = FakeDeviceInfoProvider();

  final themeController = ThemeController(storage: storage);
  final layoutController = LayoutController(
    storage: storage,
    platformInfo: platformInfo,
    deviceInfo: deviceInfo,
  );
  final inputController = InputController(platformInfo: platformInfo);

  await Future.wait([themeController.load(), layoutController.load()]);

  final module = StickyNotesModule();
  await module.initialize(storage);

  runApp(
    ProviderScope(
      overrides: [
        platformInfoProvider.overrideWithValue(platformInfo),
        storageServiceProvider.overrideWithValue(storage),
        deviceInfoProvider.overrideWithValue(deviceInfo),
        themeControllerProvider.overrideWith((ref) => themeController),
        layoutControllerProvider.overrideWith((ref) => layoutController),
        inputControllerProvider.overrideWith((ref) => inputController),
      ],
      child: StickyNotesDebugApp(module: module),
    ),
  );
}

///【临时】调试外壳根组件：MD3 主题 + DPI/字体缩放 + 输入模式监听。
class StickyNotesDebugApp extends ConsumerWidget {
  const StickyNotesDebugApp({super.key, required this.module});

  final StickyNotesModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = ref.watch(themeControllerProvider);
    final layoutController = ref.watch(layoutControllerProvider);
    final inputController = ref.watch(inputControllerProvider);

    final brightness =
        themeController.config.mode == app_theme.AppThemeMode.dark
            ? Brightness.dark
            : Brightness.light;
    final colorScheme = Md3ColorScheme.fromAccent(
      themeController.config.accentColorHex,
      brightness,
    );

    return InputDetector(
      controller: inputController,
      child: MaterialApp(
        title: '便签模块调试',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: colorScheme, useMaterial3: true),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                layoutController.effectiveDpiScale *
                    themeController.config.fontScale,
              ),
            ),
            child: child!,
          );
        },
        home: StickyNotesDebugShell(module: module),
      ),
    );
  }
}

///【临时】双页调试外壳：主页面 / 设置页。
class StickyNotesDebugShell extends ConsumerStatefulWidget {
  const StickyNotesDebugShell({super.key, required this.module});

  final StickyNotesModule module;

  @override
  ConsumerState<StickyNotesDebugShell> createState() =>
      _StickyNotesDebugShellState();
}

class _StickyNotesDebugShellState
    extends ConsumerState<StickyNotesDebugShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final settingsPage = widget.module.buildSettingsPage(context, ref);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          widget.module.buildPage(context, ref),
          settingsPage ?? const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            label: '主页面',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: '设置页',
          ),
        ],
      ),
    );
  }
}
