import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_summary.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

/// 功能模块契约接口——子项目必须实现此接口才能接入主项目。
///
/// 契约确保模块与底座在 UI 规范、状态管理、平台抽象、输入适配等方面保持一致。
/// 该接口在 TASK-02 完成后冻结，后续变更须经 ARCH + OWNER 审批。
abstract class ModuleContract {
  /// 模块定义信息（id、名称、图标、默认开关）。
  ModuleDefinition get definition;

  /// 模块主页 Widget（用户点击导航栏后进入的页面）。
  ///
  /// 必须是 [ConsumerWidget]，通过 [ref] 读取底座状态。
  Widget buildPage(BuildContext context, WidgetRef ref);

  /// 模块专属设置页 Widget（可选）。
  ///
  /// 返回 null 表示该模块没有独立设置页；返回 Widget 时，
  /// “设置 → 模块设置”点击对应模块会进入此页面。
  Widget? buildSettingsPage(BuildContext context, WidgetRef ref) => null;

  /// 模块在首页仪表盘提供的额外卡片 Widget 列表（可选）。
  ///
  /// 默认返回空列表，表示不在首页显示额外卡片。
  /// 返回的 Widget 应自行管理状态，并遵循底座卡片视觉规范。
  List<Widget> buildDashboardWidgets(BuildContext context, WidgetRef ref) => const [];

  /// 该模块是否提供自定义首页入口卡片（替换通用模块卡片）。
  ///
  /// 为 true 时，首页模块入口列表将使用 [buildEntryCard] 返回的自定义卡片，
  /// 而不是通用的模块摘要卡片。默认返回 false。
  bool get hasCustomEntryCard => false;

  /// 模块在首页入口列表的自定义入口卡片（可选）。
  ///
  /// [onOpenModule] 用于在本卡片内触发进入模块主页（切换底座导航，保留导航栏）。
  /// 返回 null 时，首页使用通用模块摘要卡片作为本模块入口。
  Widget? buildEntryCard(
    BuildContext context,
    WidgetRef ref,
    VoidCallback onOpenModule,
  ) =>
      null;

  /// 主页卡片摘要数据（显示在主页模块卡片上）。
  ///
  /// 同步返回，避免异步加载导致的卡片闪烁。
  ModuleSummary get summary;

  /// 模块初始化（应用启动时调用，用于加载模块本地数据）。
  ///
  /// 接收 [StorageService] 参数，模块不得自行访问底层存储。
  Future<void> initialize(StorageService storage);

  /// 模块销毁清理（模块被关闭或卸载时调用）。
  Future<void> dispose();

  /// 模块数据导出（用于 WebDAV 同步）。
  ///
  /// 返回模块所有需要同步的数据，key 为数据标识。
  Map<String, dynamic> exportData();

  /// 模块数据导入（用于 WebDAV 同步恢复）。
  ///
  /// 与 [exportData] 对称，保证往返一致性。
  void importData(Map<String, dynamic> data);
}
