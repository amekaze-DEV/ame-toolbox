import 'package:hive/hive.dart';

part 'module_state.g.dart';

/// 模块启用状态与显示顺序。
@HiveType(typeId: 2)
class ModuleState {
  ModuleState({
    required this.moduleId,
    required this.enabled,
    required this.displayOrder,
  });

  @HiveField(0)
  final String moduleId;

  @HiveField(1, defaultValue: true)
  bool enabled;

  @HiveField(2, defaultValue: 0)
  int displayOrder;
}
