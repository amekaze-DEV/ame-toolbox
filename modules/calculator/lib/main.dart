import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/calculator/pages/calculator_page.dart';

/// 多功能计算器模块的独立运行入口。
///
/// 该入口仅在隔离开发/测试时使用，不接入主项目底座的窗口管理、
/// 主题、同步等流程，因此启动轻量、编译快速。
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: _CalculatorStandaloneApp(),
    ),
  );
}

class _CalculatorStandaloneApp extends StatelessWidget {
  const _CalculatorStandaloneApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const CalculatorPage(),
    );
  }
}
