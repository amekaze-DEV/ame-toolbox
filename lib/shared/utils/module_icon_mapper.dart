import 'package:flutter/material.dart';

/// 将模块定义中的 [iconName] 映射为 Flutter [IconData]。
///
/// 未知名称统一返回 [Icons.extension] 占位，避免运行时异常。
class ModuleIconMapper {
  const ModuleIconMapper._();

  static final Map<String, IconData> _mapping = {
    'counter': Icons.exposure_plus_1,
    'timer': Icons.timer_outlined,
    'checklist': Icons.checklist_outlined,
    'home': Icons.home_outlined,
    'settings': Icons.settings_outlined,
  };

  static IconData map(String iconName) {
    return _mapping[iconName] ?? Icons.extension;
  }
}
