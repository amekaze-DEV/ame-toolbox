import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_summary.dart';
import 'package:ametoolbox/core/modules/module_contract.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

import 'data/todo_config_repository.dart';
import 'data/todo_list_repository.dart';
import 'pages/todo_list_page.dart';
import 'pages/todo_list_settings_page.dart';
import 'providers/holiday_data_controller.dart';
import 'providers/todo_config_controller.dart';
import 'services/holiday_data_service.dart';

/// 待办清单模块入口。
///
/// 实现 [ModuleContract]，已合并到主项目并在 [ModuleRegistry] 注册。
class TodoListModule implements ModuleContract {
  TodoConfigController? _configController;

  /// 首页卡片摘要使用的活跃待办数（启动时统计的快照）。
  int _activeCount = 0;

  @override
  ModuleDefinition get definition => const ModuleDefinition(
        id: 'todo_list',
        name: '待办清单',
        description: '类日历待办管理，支持循环周期与到期提醒',
        iconName: 'todo',
        defaultEnabled: true,
      );

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) {
    return const TodoListPage();
  }

  @override
  Widget? buildSettingsPage(BuildContext context, WidgetRef ref) {
    return const TodoListSettingsPage();
  }

  @override
  ModuleSummary get summary => ModuleSummary(
        label: '待办事项',
        value: '$_activeCount',
      );

  @override
  Future<void> initialize(StorageService storage) async {
    // 加载配置并触发节假日数据更新检查（失败自动降级，不影响启动）。
    final configRepository = TodoConfigRepository(storageService: storage);
    final configController = TodoConfigController(configRepository);
    await configController.load();
    _configController = configController;

    // 统计活跃待办数（未归档：一次性事项 + 循环模板），供首页卡片摘要展示。
    final listRepository = TodoListRepository(storageService: storage);
    final items = await listRepository.loadAll();
    _activeCount = items.where((e) => !e.isArchived).length;

    final holidayController = HolidayDataController(
      service: HolidayDataService(),
      configController: configController,
    );
    await holidayController.checkAndUpdate();
    holidayController.dispose();
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
    // TODO(P4/P9.2): 待办模块数据跨设备同步。
    // 实现时导出 `module_todo_list_config` 与 `module_todo_list_items`
    // （含图片附件 base64），见 spec §5 / ADR-TDL-005/006。
    return {};
  }

  @override
  void importData(Map<String, dynamic> data) {
    // TODO(P4/P9.2): 待办模块数据跨设备同步。
    // 实现时整体替换并做 id 去重合并（以 updatedAt 较新者为准），见 spec §5。
  }
}
