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
