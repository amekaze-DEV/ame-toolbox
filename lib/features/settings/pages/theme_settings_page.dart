import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/constants.dart';
import 'package:ametoolbox/core/models/layout_config.dart';
import 'package:ametoolbox/core/models/theme_config.dart';
import 'package:ametoolbox/core/providers/layout_provider.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/theme_provider.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';
import 'package:ametoolbox/shared/widgets/md3_slider.dart';
import 'package:ametoolbox/shared/widgets/md3_switch.dart';

/// 显示设置页。
///
/// 包含明暗主题选择、强调色选择、横竖屏断点、DPI 缩放、字体大小调节与实时预览。
class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = ref.watch(themeControllerProvider);
    final layoutController = ref.watch(layoutControllerProvider);
    final platformInfo = ref.watch(platformInfoProvider);
    final theme = themeController.config;
    final layout = layoutController.config;

    return Scaffold(
      appBar: AppBar(title: const Text('显示')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ThemeModeCard(theme: theme),
            const SizedBox(height: 16),
            _AccentColorCard(theme: theme),
            const SizedBox(height: 16),
            _BreakpointSection(
              layout: layout,
              effectiveBreakpoint: layoutController.effectiveBreakpoint,
              deviceTypeLabel: _deviceTypeLabel(platformInfo, layoutController),
            ),
            const SizedBox(height: 16),
            _DpiSection(layout: layout, effectiveDpi: layoutController.effectiveDpiScale),
            const SizedBox(height: 16),
            _FontScaleSection(theme: theme),
            const SizedBox(height: 16),
            const _PreviewCard(),
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

class _ThemeModeCard extends ConsumerWidget {
  const _ThemeModeCard({required this.theme});

  final ThemeConfig theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(themeControllerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('主题模式', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ThemeModeOption(
                    label: '明亮',
                    icon: Icons.wb_sunny_outlined,
                    selected: theme.mode == AppThemeMode.light,
                    onTap: () => controller.setMode(AppThemeMode.light),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ThemeModeOption(
                    label: '暗黑',
                    icon: Icons.nights_stay_outlined,
                    selected: theme.mode == AppThemeMode.dark,
                    onTap: () => controller.setMode(AppThemeMode.dark),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerLow,
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _AccentColorCard extends ConsumerWidget {
  const _AccentColorCard({required this.theme});

  final ThemeConfig theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(themeControllerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('强调色', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final color in AppConstants.presetColors)
                  _ColorCircle(
                    hex: color.hex,
                    displayName: color.displayName,
                    selected: theme.accentColorHex == color.hex,
                    onTap: () => controller.setAccentColor(color.hex),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  const _ColorCircle({
    required this.hex,
    required this.displayName,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final String displayName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(hex);
    return Tooltip(
      message: displayName,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
              width: 3,
            ),
          ),
          child: selected ? const Icon(Icons.check, color: Colors.white) : null,
        ),
      ),
    );
  }

  Color _parseHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
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

class _FontScaleSection extends ConsumerWidget {
  const _FontScaleSection({required this.theme});

  final ThemeConfig theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(themeControllerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('字体大小', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('${theme.fontScale.toStringAsFixed(1)}x'),
              ],
            ),
            const SizedBox(height: 8),
            Md3Slider(
              value: theme.fontScale,
              min: AppConstants.minFontScale,
              max: AppConstants.maxFontScale,
              divisions: ((AppConstants.maxFontScale - AppConstants.minFontScale) / AppConstants.fontScaleStep).round(),
              label: '${theme.fontScale.toStringAsFixed(1)}x',
              onChanged: (value) => controller.setFontScale(value),
            ),
            const SizedBox(height: 4),
            Text(
              '1.0x = 系统默认，> 1.0 放大字体，< 1.0 缩小字体',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('实时预览', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              '预览标题文字',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            AdaptiveButton(
              onPressed: () {},
              label: '主按钮',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('开关'),
                Switch(value: true, onChanged: (_) {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
