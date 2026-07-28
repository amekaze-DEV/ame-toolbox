import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/constants.dart';
import 'package:ametoolbox/core/models/layout_config.dart';
import 'package:ametoolbox/core/providers/layout_provider.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/shared/widgets/md3_slider.dart';
import 'package:ametoolbox/shared/widgets/md3_switch.dart';

/// 布局与显示设置页。
///
/// 包含横竖屏断点调节与 DPI 缩放调节，与主题页中的 DPI 设置实时联动。
class LayoutSettingsPage extends ConsumerWidget {
  const LayoutSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutController = ref.watch(layoutControllerProvider);
    final platformInfo = ref.watch(platformInfoProvider);
    final layout = layoutController.config;

    return Scaffold(
      appBar: AppBar(title: const Text('布局与显示')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BreakpointSection(
              layout: layout,
              effectiveBreakpoint: layoutController.effectiveBreakpoint,
              deviceTypeLabel: _deviceTypeLabel(platformInfo, layoutController),
            ),
            const SizedBox(height: 16),
            _DpiSection(
              layout: layout,
              effectiveDpi: layoutController.effectiveDpiScale,
            ),
          ],
        ),
      ),
    );
  }

  String _deviceTypeLabel(dynamic platformInfo, dynamic layoutController) {
    if (platformInfo.isDesktop) return '桌面';
    final shortSide = layoutController.screenSize.shortestSide;
    if (shortSide < AppConstants.phoneMaxShortSide) return '手机';
    if (shortSide < AppConstants.tabletMaxShortSide) return '平板';
    return '桌面';
  }
}

class _BreakpointSection extends ConsumerWidget {
  const _BreakpointSection({
    required this.layout,
    required this.effectiveBreakpoint,
    required this.deviceTypeLabel,
  });

  final LayoutConfig layout;
  final double effectiveBreakpoint;
  final String deviceTypeLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(layoutControllerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('横竖屏断点', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(layout.autoBreakpoint ? '自动' : '手动'),
                Md3Switch(
                  value: layout.autoBreakpoint,
                  onChanged: (value) => controller.setAutoBreakpoint(value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (layout.autoBreakpoint)
              Text('自动 · $deviceTypeLabel · ${effectiveBreakpoint.toStringAsFixed(2)}')
            else
              Column(
                children: [
                  Text(layout.breakpoint.toStringAsFixed(2)),
                  Md3Slider(
                    value: layout.breakpoint,
                    min: AppConstants.minBreakpoint,
                    max: AppConstants.maxBreakpoint,
                    divisions: ((AppConstants.maxBreakpoint - AppConstants.minBreakpoint) / AppConstants.breakpointStep).round(),
                    label: layout.breakpoint.toStringAsFixed(2),
                    onChanged: (value) => controller.setBreakpoint(value),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              '宽高比 ≥ 断点值时切换为横屏布局',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DpiSection extends ConsumerWidget {
  const _DpiSection({required this.layout, required this.effectiveDpi});

  final LayoutConfig layout;
  final double effectiveDpi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(layoutControllerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('DPI 缩放', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(layout.autoDpi ? '自动' : '手动'),
                Md3Switch(
                  value: layout.autoDpi,
                  onChanged: (value) => controller.setAutoDpi(value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (layout.autoDpi)
              Text('自动 (${effectiveDpi.toStringAsFixed(2)}x)')
            else
              Column(
                children: [
                  Text('${layout.dpiScale.toStringAsFixed(1)}x'),
                  Md3Slider(
                    value: layout.dpiScale,
                    min: AppConstants.minDpiScale,
                    max: AppConstants.maxDpiScale,
                    divisions: ((AppConstants.maxDpiScale - AppConstants.minDpiScale) / AppConstants.dpiStep).round(),
                    label: '${layout.dpiScale.toStringAsFixed(1)}x',
                    onChanged: (value) => controller.setDpiScale(value),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
