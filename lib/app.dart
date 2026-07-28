import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/theme_config.dart' as app_theme;
import 'package:ametoolbox/core/providers/input_provider.dart';
import 'package:ametoolbox/core/providers/layout_provider.dart';
import 'package:ametoolbox/core/providers/theme_provider.dart';
import 'package:ametoolbox/core/theme/md3_color_scheme.dart';
import 'package:ametoolbox/features/module_management/module_management_page.dart';
import 'package:ametoolbox/features/settings/layout_settings_page.dart';
import 'package:ametoolbox/features/settings/theme_settings_page.dart';

/// 应用根 Widget。
///
/// 注入 MD3 主题、DPI/字体缩放、输入模式监听。
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = ref.watch(themeControllerProvider);
    final layoutController = ref.watch(layoutControllerProvider);
    final inputController = ref.watch(inputControllerProvider);

    final brightness = themeController.config.mode == app_theme.AppThemeMode.dark
        ? Brightness.dark
        : Brightness.light;
    final colorScheme = Md3ColorScheme.fromAccent(
      themeController.config.accentColorHex,
      brightness,
    );

    return InputModeScope(
      mode: inputController.mode,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerHover: inputController.onPointerEvent,
        onPointerDown: inputController.onPointerEvent,
        child: AnimatedTheme(
          data: ThemeData(
            colorScheme: colorScheme,
            useMaterial3: true,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: MaterialApp(
            title: 'AMEToolbox',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: colorScheme,
              useMaterial3: true,
            ),
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
            home: const _HomeShell(),
          ),
        ),
      ),
    );
  }
}

/// 临时主页壳层，提供进入模块管理页面的入口。
///
/// TASK-05 导航与主页将替换为正式主页。
class _HomeShell extends StatelessWidget {
  const _HomeShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主页'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: '主题设置',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ThemeSettingsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.aspect_ratio),
            tooltip: '布局与显示',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LayoutSettingsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: '模块管理',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ModuleManagementPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('AMEToolbox')),
    );
  }
}
