import 'package:flutter/material.dart';

/// 首页与子模块共用的文本样式规范。
///
/// MD3 的 `titleMedium` / `titleSmall` 默认字重为 `w500`，各处直接引用时
/// 会因字形与颜色差异呈现出粗细不一致的观感。卡片主标题与卡片内小节标题
/// 统一在此收敛为加粗，子模块通过 `package:ametoolbox` 复用同一定义。
class AppTextStyles {
  const AppTextStyles._();

  /// 模块卡片主标题：MD3 `titleMedium` + 加粗。
  static TextStyle? cardTitle(BuildContext context) => Theme.of(context)
      .textTheme
      .titleMedium
      ?.copyWith(fontWeight: FontWeight.bold);

  /// 卡片内小节标题：MD3 `titleSmall` + 加粗 + 次要文本色。
  static TextStyle? sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
}
