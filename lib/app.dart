import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/theme_config.dart' as app_theme;
import 'package:ametoolbox/core/providers/input_provider.dart';
import 'package:ametoolbox/core/providers/layout_provider.dart';
import 'package:ametoolbox/core/providers/theme_provider.dart';
import 'package:ametoolbox/features/module_management/module_management_page.dart';

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
    final seedColor = _parseHex(themeController.config.accentColorHex);

    return InputModeScope(
      mode: inputController.mode,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerHover: inputController.onPointerEvent,
        onPointerDown: inputController.onPointerEvent,
        child: MaterialApp(
          title: 'AMEToolbox',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: brightness,
            ),
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
    );
  }

  Color _parseHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
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
