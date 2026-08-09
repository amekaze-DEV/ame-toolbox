import 'package:hive/hive.dart';

part 'module_state.g.dart';

/// 模块启用状态与显示顺序。
@HiveType(typeId: 2)
class ModuleState {
  ModuleState({
    required this.moduleId,
    required this.enabled,
    required this.displayOrder,
    this.displayOrderLandscape,
  });

  @HiveField(0)
  final String moduleId;

  @HiveField(1, defaultValue: true)
  bool enabled;

  /// 竖屏/单列布局下的显示顺序。
  @HiveField(2, defaultValue: 0)
  int displayOrder;

  /// 横屏/双列布局下的显示顺序。
  ///
  /// 为 null 时使用 [displayOrder] 作为默认横屏顺序，保证首次切换横屏时
  /// 与竖屏顺序一致。横屏下重新排序后写入独立值，实现横竖屏排序解耦。
  @HiveField(3)
  int? displayOrderLandscape;
}
