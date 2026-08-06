import 'dart:async';

import 'package:ametoolbox/core/storage/storage_service.dart';

import '../models/calculator_config.dart';

/// 多功能计算器模块配置仓库。
///
/// 封装 [StorageService]，负责 [CalculatorConfig] 的持久化读写。
/// 所有业务数据 key 均使用 `module_calculator_` 前缀。
class CalculatorConfigRepository {
  final StorageService _storage;

  static const String _configKey = 'module_calculator_config';

  CalculatorConfigRepository({required this._storage});

  /// 读取模块配置；首次读取或数据不存在时返回 [CalculatorConfig.defaults]。
  Future<CalculatorConfig> loadConfig() async {
    try {
      final data = await _storage.loadData(_configKey);
      if (data == null) return CalculatorConfig.defaults;
      return CalculatorConfig.fromJson(data);
    } catch (e) {
      // 读取异常时回退到默认配置，避免模块无法启动。
      return CalculatorConfig.defaults;
    }
  }

  /// 保存模块配置。
  Future<void> saveConfig(CalculatorConfig config) async {
    await _storage.saveData(_configKey, config.toJson());
  }

  /// 删除模块配置。
  Future<void> deleteConfig() async {
    await _storage.deleteData(_configKey);
  }
}
