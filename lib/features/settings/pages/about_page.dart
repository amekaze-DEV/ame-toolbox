import 'package:flutter/material.dart';

/// 关于应用页。
///
/// 显示应用名称、版本号、版权等静态信息。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于应用')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'AMEToolbox',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('版本 v1.0.0'),
            SizedBox(height: 16),
            Text('工业现场工具箱'),
          ],
        ),
      ),
    );
  }
}
