/// AMEToolbox 全局预设常量。
///
/// 包含默认主题/布局/DPI 配置、强调色列表、断点阈值等。
class AppConstants {
  const AppConstants._();

  /// 预设强调色列表。
  static const List<({String name, String hex, String displayName})>
      presetColors = [
    (name: 'safety_orange', hex: '#E85D04', displayName: '安全橙'),
    (name: 'industrial_blue', hex: '#1565C0', displayName: '工业蓝'),
    (name: 'safety_green', hex: '#2D7D46', displayName: '安全绿'),
    (name: 'warning_red', hex: '#C62828', displayName: '警示红'),
    (name: 'purple', hex: '#6A1B9A', displayName: '紫'),
    (name: 'yellow', hex: '#F9A825', displayName: '黄'),
  ];

  /// 默认强调色 HEX 值。
  static const String defaultAccentColorHex = '#E85D04';

  // ── 默认配置 ──
  static const bool defaultAutoBreakpoint = true;
  static const bool defaultAutoDpi = true;
  static const double defaultBreakpoint = 1.20;
  static const double defaultDpiScale = 1.0;
  static const double defaultFontScale = 1.0;

  // ── 断点范围 ──
  static const double minBreakpoint = 1.00;
  static const double maxBreakpoint = 2.00;
  static const double breakpointStep = 0.05;

  // ── DPI 范围 ──
  static const double minDpiScale = 0.8;
  static const double maxDpiScale = 1.5;
  static const double dpiStep = 0.1;

  // ── 字体缩放范围 ──
  static const double minFontScale = 0.8;
  static const double maxFontScale = 1.5;
  static const double fontScaleStep = 0.1;

  // ── 自动断点判定阈值（按设备短边 dp 划分）──
  static const double phoneMaxShortSide = 600;
  static const double tabletMaxShortSide = 840;
  static const double autoBreakpointPhone = 1.00;
  static const double autoBreakpointTablet = 1.30;
  static const double autoBreakpointDesktop = 1.20;

  // ── 自动 DPI 基准 ──
  static const double desktopBaseDpi = 96.0;

  // ── 输入模式切换防抖 ──
  static const int inputModeDebounceMs = 300;

  // ── 窗口最小尺寸 ──
  static const double windowMinWidth = 400;
  static const double windowMinHeight = 600;

  // ── 动画时长 ──
  static const int transitionDurationMs = 300;

  // ── 默认模块清单 ──
  static const List<({String id, String name, String description, String iconName})>
      defaultModules = [
    (
      id: 'counter',
      name: '计数器',
      description: '产线计数、批次记录',
      iconName: 'counter',
    ),
    (
      id: 'timer',
      name: '计时器',
      description: '工序计时、节拍管控',
      iconName: 'timer',
    ),
    (
      id: 'checklist',
      name: '检查表',
      description: '设备点检、安全巡检',
      iconName: 'checklist',
    ),
  ];
}
