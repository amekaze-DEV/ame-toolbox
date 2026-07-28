import 'package:flutter/material.dart';

/// MD3 风格滑块。
///
/// Flutter 在 [ThemeData.useMaterial3] 为 true 时，[Slider] 已自动使用 MD3 视觉风格。
/// 本组件做轻量封装，统一禁用态行为并补充标签显示。
class Md3Slider extends StatelessWidget {
  const Md3Slider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.label,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      label: label,
      onChanged: onChanged,
    );
  }
}
