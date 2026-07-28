import 'package:flutter/material.dart';

/// MD3 色彩方案生成器。
///
/// 以强调色为种子，通过 [ColorScheme.fromSeed] 生成完整的 MD3 色彩梯度。
/// 所有颜色均从 [Theme.of(context).colorScheme] 获取，UI 层不硬编码色值。
class Md3ColorScheme {
  const Md3ColorScheme._();

  /// 根据强调色 HEX 与亮度生成 [ColorScheme]。
  static ColorScheme fromAccent(String hex, Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: _parseHex(hex),
      brightness: brightness,
    );
  }

  static Color _parseHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
