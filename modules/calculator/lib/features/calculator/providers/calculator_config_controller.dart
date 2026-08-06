import 'package:flutter/foundation.dart';

import '../data/calculator_config_repository.dart';
import '../models/calculator_config.dart';
import '../models/calculation_history.dart';
import '../models/calculator_type.dart';
import '../models/exchange_rate_cache.dart';

/// 多功能计算器模块配置控制器。
///
/// 持有 [CalculatorConfig] 状态，所有配置变更均通过此控制器进行，
/// 变更后即时持久化到 [CalculatorConfigRepository]。
class CalculatorConfigController extends ChangeNotifier {
  final CalculatorConfigRepository _repository;

  CalculatorConfig _config;

  CalculatorConfigController({
    required this._repository,
    CalculatorConfig? initialConfig,
  }) : _config = initialConfig ?? CalculatorConfig.defaults;

  /// 当前配置。
  CalculatorConfig get config => _config;

  /// 从仓库加载配置；首次调用应在模块初始化时执行。
  Future<void> load() async {
    _config = await _repository.loadConfig();
    notifyListeners();
  }

  /// 切换当前计算器类型。
  Future<void> setCurrentType(CalculatorType type) async {
    if (_config.currentType == type) return;
    await _updateConfig(_config.copyWith(currentType: type));
  }

  /// 设置小数精度。
  Future<void> setDecimalPrecision(int precision) async {
    final clamped = precision.clamp(0, 10);
    if (_config.decimalPrecision == clamped) return;
    await _updateConfig(_config.copyWith(decimalPrecision: clamped));
  }

  /// 设置科学计数法显示开关。
  Future<void> setScientificNotation(bool enabled) async {
    if (_config.scientificNotation == enabled) return;
    await _updateConfig(_config.copyWith(scientificNotation: enabled));
  }

  /// 设置横屏历史面板位置。
  Future<void> setHistoryPanelOnLeft(bool onLeft) async {
    if (_config.historyPanelOnLeft == onLeft) return;
    await _updateConfig(_config.copyWith(historyPanelOnLeft: onLeft));
  }

  /// 设置是否显示完整数字键盘。
  Future<void> setShowFullKeyboard(bool show) async {
    if (_config.showFullKeyboard == show) return;
    await _updateConfig(_config.copyWith(showFullKeyboard: show));
  }

  /// 设置首页快速计算器卡片开关。
  Future<void> setDashboardQuickCalc(bool enabled) async {
    if (_config.dashboardQuickCalc == enabled) return;
    await _updateConfig(_config.copyWith(dashboardQuickCalc: enabled));
  }

  /// 设置首页历史卡片开关。
  Future<void> setDashboardHistory(bool enabled) async {
    if (_config.dashboardHistory == enabled) return;
    await _updateConfig(_config.copyWith(dashboardHistory: enabled));
  }

  /// 设置首页卡片排序。
  Future<void> setDashboardOrders({
    required int quickCalcOrder,
    required int historyOrder,
  }) async {
    if (_config.dashboardQuickCalcOrder == quickCalcOrder &&
        _config.dashboardHistoryOrder == historyOrder) {
      return;
    }
    await _updateConfig(
      _config.copyWith(
        dashboardQuickCalcOrder: quickCalcOrder,
        dashboardHistoryOrder: historyOrder,
      ),
    );
  }

  /// 设置自定义汇率源地址。
  Future<void> setExchangeRateApiUrl(String url) async {
    if (_config.exchangeRateApiUrl == url) return;
    await _updateConfig(_config.copyWith(exchangeRateApiUrl: url));
  }

  /// 设置进制 NOT 位宽。
  Future<void> setRadixNotBitWidth(int width) async {
    final validWidths = [8, 16, 32, 64];
    final clamped = validWidths.contains(width) ? width : 32;
    if (_config.radixNotBitWidth == clamped) return;
    await _updateConfig(_config.copyWith(radixNotBitWidth: clamped));
  }

  /// 替换历史记录列表。
  Future<void> setHistory(List<CalculationHistory> history) async {
    await _updateConfig(_config.copyWith(history: history));
  }

  /// 添加一条历史记录；超过 20 条时保留最新的 20 条。
  Future<void> addHistory(CalculationHistory record) async {
    final newHistory = [record, ..._config.history];
    if (newHistory.length > 20) {
      newHistory.removeRange(20, newHistory.length);
    }
    await _updateConfig(_config.copyWith(history: newHistory));
  }

  /// 清空历史记录。
  Future<void> clearHistory() async {
    if (_config.history.isEmpty) return;
    await _updateConfig(_config.copyWith(history: const []));
  }

  /// 设置汇率缓存。
  Future<void> setExchangeRates(ExchangeRateCache? cache) async {
    if (_config.exchangeRates == cache) return;
    await _updateConfig(_config.copyWith(exchangeRates: cache));
  }

  /// 使用新配置全量更新。
  Future<void> updateConfig(CalculatorConfig config) async {
    if (_config == config) return;
    await _updateConfig(config);
  }

  Future<void> _updateConfig(CalculatorConfig newConfig) async {
    _config = newConfig;
    await _repository.saveConfig(_config);
    notifyListeners();
  }
}
