import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/models/layout_mode.dart';
import 'package:ametoolbox/core/providers/layout_provider.dart';

/// 根据当前 [LayoutMode] 构建不同子树的 Builder。
typedef LayoutWidgetBuilder = Widget Function(BuildContext context);

/// 响应式布局构建器。
///
/// 监听 [LayoutController] 的状态变化，自动在竖屏/横屏子树之间切换，
/// 并附带 300ms 的平滑过渡动画。
class ResponsiveBuilder extends ConsumerWidget {
  const ResponsiveBuilder({
    super.key,
    required this.portraitBuilder,
    required this.landscapeBuilder,
  });

  final LayoutWidgetBuilder portraitBuilder;
  final LayoutWidgetBuilder landscapeBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutMode = ref.watch(layoutControllerProvider).layoutMode;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: KeyedSubtree(
        key: ValueKey<LayoutMode>(layoutMode),
        child: layoutMode == LayoutMode.landscape
            ? landscapeBuilder(context)
            : portraitBuilder(context),
      ),
    );
  }
}
