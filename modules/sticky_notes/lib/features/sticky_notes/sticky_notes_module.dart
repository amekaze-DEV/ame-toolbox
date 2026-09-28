import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_summary.dart';
import 'package:ametoolbox/core/modules/module_contract.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

import 'data/sticky_notes_config_repository.dart';
import 'data/sticky_notes_repository.dart';
import 'pages/sticky_notes_page.dart';
import 'pages/sticky_notes_settings_page.dart';
import 'providers/sticky_notes_config_controller.dart';

/// 便签模块入口。
///
/// 实现 [ModuleContract]，接入底座生命周期；
/// 合并主线时由主项目 [ModuleRegistry] 注册。
class StickyNotesModule implements ModuleContract {
  StickyNotesConfigController? _configController;

  /// 首页卡片摘要使用的便签数（启动时统计的快照）。
  int _total = 0;

  @override
  ModuleDefinition get definition => const ModuleDefinition(
        id: 'sticky_notes',
        name: '便签',
        description: '便签记录、分类与置顶管理',
        iconName: 'notes',
        defaultEnabled: true,
      );

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) {
    return const StickyNotesPage();
  }

  @override
  Widget? buildSettingsPage(BuildContext context, WidgetRef ref) {
    return const StickyNotesSettingsPage();
  }

  @override
  ModuleSummary get summary => ModuleSummary(
        label: '便签',
        value: '$_total',
      );

  @override
  Future<void> initialize(StorageService storage) async {
    // 加载配置（首次运行写入默认分类与默认排序）。
    final configRepository = StickyNotesConfigRepository(
      storageService: storage,
    );
    final configController = StickyNotesConfigController(configRepository);
    await configController.load();
    _configController = configController;

    // 统计便签总数，供首页卡片摘要展示。
    final notesRepository = StickyNotesRepository(storageService: storage);
    final notes = await notesRepository.loadAll();
    _total = notes.length;
  }

  @override
  Future<void> dispose() async {
    _configController?.dispose();
    _configController = null;
  }

  @override
  List<Widget> buildDashboardWidgets(BuildContext context, WidgetRef ref) =>
      const [];

  @override
  bool get hasCustomEntryCard => false;

  @override
  Widget? buildEntryCard(
    BuildContext context,
    WidgetRef ref,
    VoidCallback onOpenModule,
  ) =>
      null;

  @override
  Map<String, dynamic> exportData() {
    // TODO(P10.5): 导出 module_sticky_notes_config 与 module_sticky_notes_notes
    // （含图片附件 base64），见 spec §5 / ADR-SN-003。
    return <String, dynamic>{};
  }

  @override
  void importData(Map<String, dynamic> data) {
    // TODO(P10.5): 整体替换配置并按 id 合并便签（以 updatedAt 较新者为准）。
  }
}
