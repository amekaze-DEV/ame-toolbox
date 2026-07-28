import 'package:hive/hive.dart';

part 'layout_config.g.dart';

/// 布局配置数据。
@HiveType(typeId: 3)
class LayoutConfig {
  LayoutConfig({
    this.autoBreakpoint = true,
    this.breakpoint = 1.20,
    this.autoDpi = true,
    this.dpiScale = 1.0,
  });

  /// 是否启用自动断点。
  @HiveField(0, defaultValue: true)
  bool autoBreakpoint;

  /// 手动断点值（仅 autoBreakpoint=false 时生效）。
  @HiveField(1, defaultValue: 1.20)
  double breakpoint;

  /// 是否启用自动 DPI。
  @HiveField(2, defaultValue: true)
  bool autoDpi;

  /// 手动 DPI 缩放因子（仅 autoDpi=false 时生效）。
  @HiveField(3, defaultValue: 1.0)
  double dpiScale;
}
