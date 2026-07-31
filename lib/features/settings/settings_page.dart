import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/constants.dart';
import 'package:ametoolbox/core/models/sync_config.dart';
import 'package:ametoolbox/core/models/theme_config.dart';
import 'package:ametoolbox/core/modules/module_contract.dart';
import 'package:ametoolbox/core/providers/layout_provider.dart';
import 'package:ametoolbox/core/providers/module_provider.dart';
import 'package:ametoolbox/core/providers/sync_provider.dart';
import 'package:ametoolbox/core/providers/theme_provider.dart';
import 'package:ametoolbox/features/settings/pages/about_page.dart';
import 'package:ametoolbox/features/settings/pages/sync_settings_page.dart';
import 'package:ametoolbox/features/settings/pages/theme_settings_page.dart';
import 'package:ametoolbox/features/settings/widgets/settings_list_tile.dart';
import 'package:ametoolbox/features/settings/widgets/settings_section.dart';
import 'package:ametoolbox/shared/utils/module_icon_mapper.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';
import 'package:ametoolbox/shared/widgets/md3_switch.dart';

/// 设置页。
///
/// 分为全局设置、同步设置、模块设置三大分区。
/// 同步设置带总开关；模块设置中每个模块独立开关，开启后显示该模块的专属设置入口。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);
    final config = syncService.config;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 全局设置分区（始终展开）
            SettingsSection(
              title: '全局设置',
              children: [
                SettingsListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: '显示',
                  subtitle: _displaySummary(ref),
                  onTap: () => _navigate(context, const ThemeSettingsPage()),
                ),
                SettingsListTile(
                  leading: const Icon(Icons.info_outline),
                  title: '关于应用',
                  subtitle: 'v1.0.0',
                  onTap: () => _navigate(context, const AboutPage()),
                ),
              ],
            ),
            // 同步设置分区（带总开关）
            SettingsSection(
              title: '同步设置',
              switchValue: config.enabled,
              onSwitchChanged: (value) => _toggleSync(ref, value),
              confirmDismiss: () => _confirmSyncDisable(context),
              children: [
                SettingsListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: 'WebDAV 服务器',
                  subtitle: config.serverUrl.isEmpty ? '未配置' : config.serverUrl,
                  onTap: () => _navigate(context, const SyncSettingsPage()),
                ),
                SettingsListTile(
                  leading: const Icon(Icons.person_outline),
                  title: '账号凭据',
                  subtitle: config.username.isEmpty ? '未配置' : config.username,
                  onTap: () => _navigate(context, const SyncSettingsPage()),
                ),
                SettingsListTile(
                  leading: const Icon(Icons.schedule),
                  title: '同步频率',
                  subtitle: _frequencyLabel(config.frequency),
                  onTap: () => _navigate(context, const SyncSettingsPage()),
                ),
                SettingsListTile(
                  leading: const Icon(Icons.sync),
                  title: '立即同步',
                  trailing: syncService.isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: syncService.isSyncing ? null : () => syncService.startSync(),
                ),
                SettingsListTile(
                  leading: _statusIcon(config, syncService.isSyncing),
                  title: '同步状态',
                  subtitle: _statusText(config, syncService.isSyncing),
                  onTap: null,
                ),
              ],
            ),
            // 模块设置分区（每个模块独立开关）
            _buildModuleSection(ref, context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleSection(WidgetRef ref, BuildContext context) {
    final moduleController = ref.watch(moduleControllerProvider);
    final modules = moduleController.registeredModules;

    return SettingsSection(
      title: '模块设置',
      children: [
        for (final module in modules) ...[
          SettingsListTile(
            leading: Icon(ModuleIconMapper.map(module.definition.iconName)),
            title: module.definition.name,
            trailing: Md3Switch(
              value: moduleController.isEnabled(module.definition.id),
              onChanged: (_) => _toggleModule(ref, module.definition.id),
            ),
            onTap: () => _toggleModule(ref, module.definition.id),
          ),
          if (moduleController.isEnabled(module.definition.id))
            SettingsListTile(
              leading: const Icon(Icons.settings_outlined),
              title: '${module.definition.name}设置',
              subtitle: '配置该模块',
              onTap: () => _openModuleSettings(context, module, ref),
            ),
        ],
      ],
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  Future<void> _toggleModule(WidgetRef ref, String moduleId) async {
    final moduleController = ref.read(moduleControllerProvider);
    await moduleController.toggleModule(moduleId);
  }

  void _openModuleSettings(
    BuildContext context,
    ModuleContract module,
    WidgetRef ref,
  ) {
    final settingsPage = module.buildSettingsPage(context, ref);
    if (settingsPage != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => settingsPage),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${module.definition.name} 暂无专属设置页')),
      );
    }
  }

  String _displaySummary(WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider).config;
    final layout = ref.watch(layoutControllerProvider).config;
    final modeLabel = theme.mode == AppThemeMode.light ? '明亮' : '暗黑';
    final color = AppConstants.presetColors.firstWhere(
      (c) => c.hex == theme.accentColorHex,
      orElse: () => (name: 'custom', hex: theme.accentColorHex, displayName: '自定义'),
    );
    final dpi = layout.autoDpi ? '自动' : '${layout.dpiScale.toStringAsFixed(1)}x';
    return '$modeLabel · ${color.displayName} · 字体 ${theme.fontScale.toStringAsFixed(1)}x · DPI $dpi';
  }

  String _frequencyLabel(SyncFrequency frequency) {
    return switch (frequency) {
      SyncFrequency.manual => '手动',
      SyncFrequency.fiveMin => '每 5 分钟',
      SyncFrequency.fifteenMin => '每 15 分钟',
      SyncFrequency.sixtyMin => '每 60 分钟',
    };
  }

  Widget _statusIcon(SyncConfig config, bool isSyncing) {
    if (isSyncing) return const Icon(Icons.sync);
    return switch (config.lastSyncStatus) {
      SyncStatus.success => const Icon(Icons.check_circle),
      SyncStatus.failed => const Icon(Icons.error),
      _ => const Icon(Icons.cloud_off),
    };
  }

  String _statusText(SyncConfig config, bool isSyncing) {
    if (isSyncing) return '同步中…';
    return switch (config.lastSyncStatus) {
      SyncStatus.success => config.lastSyncTime != null
          ? '已同步 · ${_formatTime(config.lastSyncTime!)}'
          : '已同步',
      SyncStatus.failed => '同步失败',
      _ => '未同步',
    };
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleSync(WidgetRef ref, bool value) async {
    final syncService = ref.read(syncServiceProvider);
    await syncService.updateConfig(syncService.config.copyWith(enabled: value));
  }

  Future<bool> _confirmSyncDisable(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关闭同步'),
        content: const Text('关闭后将停止自动同步并隐藏 WebDAV 配置项，是否继续？'),
        actions: [
          AdaptiveButton(
            variant: AdaptiveButtonVariant.text,
            onPressed: () => Navigator.of(context).pop(false),
            label: '取消',
          ),
          AdaptiveButton(
            variant: AdaptiveButtonVariant.text,
            onPressed: () => Navigator.of(context).pop(true),
            label: '关闭',
          ),
        ],
      ),
    );
    return result ?? false;
  }

}
