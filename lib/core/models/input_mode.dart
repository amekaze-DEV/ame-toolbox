/// 当前活跃的输入方式，由 InputDetector 自动检测并切换。
enum InputMode {
  /// 触控模式：大点击区域、无悬停态、滑动手势优先。
  touch,

  /// 键鼠模式：精确点击、悬停高亮、右键菜单、键盘快捷键。
  mouse,
}
