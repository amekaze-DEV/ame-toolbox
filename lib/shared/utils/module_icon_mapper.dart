import 'package:flutter/material.dart';

/// 将模块定义中的 [iconName] 映射为 Flutter [IconData]。
///
/// 未知名称统一返回 [Icons.extension] 占位，避免运行时异常。
class ModuleIconMapper {
  const ModuleIconMapper._();

  static final Map<String, IconData> _mapping = {
    'shift': Icons.calendar_month_outlined,
    'calculator': Icons.calculate_outlined,
    'todo': Icons.check_circle_outline,
    'checklist': Icons.checklist_outlined,
    'notes': Icons.sticky_note_2_outlined,
    'home': Icons.home_outlined,
    'settings': Icons.settings_outlined,
  };

  static IconData map(String iconName) {
    return _mapping[iconName] ?? Icons.extension;
  }
}
