import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/models/sync_config.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:ametoolbox/core/providers/sync_provider.dart';
import 'package:ametoolbox/core/sync/sync_service.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';
import 'package:ametoolbox/shared/widgets/adaptive_list_tile.dart';

/// WebDAV 同步设置页。
///
/// 提供服务器地址、账号凭据、同步频率配置与手动同步触发。
/// 实际 WebDAV 协议实现在 TASK-07 中完成。
class SyncSettingsPage extends ConsumerStatefulWidget {
  const SyncSettingsPage({super.key});

  @override
  ConsumerState<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends ConsumerState<SyncSettingsPage> {
  late final TextEditingController _serverController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(syncServiceProvider).config;
    _serverController = TextEditingController(text: config.serverUrl);
    _usernameController = TextEditingController(text: config.username);
    _passwordController = TextEditingController();
    _loadPassword();
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    try {
      await ref.read(syncServiceProvider).testConnection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('连接成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _loadPassword() async {
    final storage = ref.read(storageServiceProvider);
    final password = await storage.getWebDavPassword() ?? '';
    if (mounted) {
      setState(() {
        _passwordController.text = password;
      });
    }
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncService = ref.watch(syncServiceProvider);
    final config = syncService.config;

    return Scaffold(
      appBar: AppBar(title: const Text('同步设置')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServerSection(config),
            const SizedBox(height: 16),
            _buildCredentialsSection(config),
            const SizedBox(height: 16),
            _buildFrequencySection(config),
            const SizedBox(height: 16),
            _buildActionSection(syncService),
            if (syncService.errorMessage != null) ...[
              const SizedBox(height: 12),
              _buildErrorSection(syncService.errorMessage!),
            ],
            if (syncService.isSyncing && syncService.progress != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: syncService.progress),
            ],
            const SizedBox(height: 16),
            _buildStatusSection(config, syncService.isSyncing),
          ],
        ),
      ),
    );
  }

  Widget _buildServerSection(SyncConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WebDAV 服务器', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _serverController,
              decoration: const InputDecoration(
                hintText: 'https://example.com/dav',
                prefixIcon: Icon(Icons.cloud_outlined),
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => _saveConfig(config),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsSection(SyncConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('账号凭据', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                prefixIcon: Icon(Icons.person_outline),
              ),
              onChanged: (_) => _saveConfig(config),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '密码',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              onChanged: (_) => _savePassword(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySection(SyncConfig config) {
    final labels = {
      SyncFrequency.manual: '手动',
      SyncFrequency.fiveMin: '每 5 分钟',
      SyncFrequency.fifteenMin: '每 15 分钟',
      SyncFrequency.sixtyMin: '每 60 分钟',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('同步频率', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<SyncFrequency>(
              initialValue: config.frequency,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.schedule),
              ),
              items: [
                for (final entry in labels.entries)
                  DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                _saveConfig(config.copyWith(frequency: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection(SyncService syncService) {
    final canSync = syncService.config.enabled && !syncService.isSyncing;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('操作', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AdaptiveButton(
                    variant: AdaptiveButtonVariant.tonal,
                    icon: _isTesting ? null : Icons.link,
                    onPressed: _isTesting ? null : _testConnection,
                    label: _isTesting ? '测试中…' : '测试连接',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdaptiveButton(
                    icon: syncService.isSyncing ? null : Icons.sync,
                    onPressed: canSync ? () => syncService.startSync() : null,
                    label: syncService.isSyncing ? '同步中…' : '立即同步',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection(String message) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(SyncConfig config, bool isSyncing) {
    final (icon, text, color) = _statusInfo(config, isSyncing);

    return Card(
      child: AdaptiveListTile(
        leading: Icon(icon, color: color),
        title: const Text('同步状态'),
        subtitle: Text(text),
      ),
    );
  }

  (IconData, String, Color?) _statusInfo(SyncConfig config, bool isSyncing) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isSyncing) {
      return (Icons.sync, '同步中…', colorScheme.primary);
    }

    switch (config.lastSyncStatus) {
      case SyncStatus.success:
        final time = config.lastSyncTime != null
            ? '${config.lastSyncTime!.hour.toString().padLeft(2, '0')}:${config.lastSyncTime!.minute.toString().padLeft(2, '0')}'
            : '';
        return (Icons.check_circle, '已同步 · $time', colorScheme.tertiary);
      case SyncStatus.failed:
        return (Icons.error, '同步失败', colorScheme.error);
      case SyncStatus.idle:
      default:
        return (Icons.cloud_off, '未配置', colorScheme.outline);
    }
  }

  Future<void> _saveConfig(SyncConfig base) async {
    final updated = base.copyWith(
      serverUrl: _serverController.text,
      username: _usernameController.text,
    );
    await ref.read(syncServiceProvider).updateConfig(updated);
  }

  Future<void> _savePassword() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setWebDavPassword(_passwordController.text);
  }
}
