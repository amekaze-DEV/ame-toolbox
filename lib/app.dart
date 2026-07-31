import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/input/input_detector.dart';
import 'package:ametoolbox/core/input/keyboard_shortcuts.dart';
import 'package:ametoolbox/core/models/theme_config.dart' as app_theme;
import 'package:ametoolbox/core/providers/input_provider.dart';
import 'package:ametoolbox/core/providers/layout_provider.dart';
import 'package:ametoolbox/core/providers/theme_provider.dart';
import 'package:ametoolbox/core/theme/md3_color_scheme.dart';
import 'package:ametoolbox/features/home/home_page.dart';

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

    return InputDetector(
      controller: inputController,
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
              child: KeyboardShortcuts(child: child!),
            );
          },
          home: const HomePage(),
        ),
      ),
    );
  }
}
