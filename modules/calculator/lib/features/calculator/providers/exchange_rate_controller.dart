import 'package:flutter/foundation.dart';

import '../models/calculation_history.dart';
import '../models/calculator_type.dart';
import '../models/exchange_rate_cache.dart';
import '../services/exchange_rate_service.dart';
import '../services/scientific_calculator_service.dart';
import 'calculator_config_controller.dart';

/// 汇率计算器状态控制器。
///
/// 持有货币选择、金额输入、汇率缓存与刷新状态，
/// 并将成功获取的汇率缓存持久化到配置中。
class ExchangeRateController extends ChangeNotifier {
  final ExchangeRateService _service;
  final CalculatorConfigController _configController;

  String _fromCurrency = 'USD';
  String _toCurrency = 'CNY';
  String _amount = '';
  String _result = '';

  ExchangeRateStatus _status = ExchangeRateStatus.idle;
  String? _message;

  /// 等待构造函数中的自动刷新（如有）完成。
  late final Future<void> didInitialize;

  late bool _lastScientificNotation;
  late int _lastDecimalPrecision;

  ExchangeRateController({
    required this._service,
    required this._configController,
  }) {
    _lastScientificNotation = _configController.config.scientificNotation;
    _lastDecimalPrecision = _configController.config.decimalPrecision;
    _configController.addListener(_onConfigChanged);

    final cache = _configController.config.exchangeRates;
    if (cache != null && cache.rates.isNotEmpty) {
      _fromCurrency = cache.baseCurrency;
      _status = ExchangeRateStatus.success;
      _message = null;
      didInitialize = Future.value();
    } else {
      // 无缓存时自动刷新汇率，确保输入金额后可立即换算。
      didInitialize = refresh();
    }
  }

  @override
  void dispose() {
    _configController.removeListener(_onConfigChanged);
    super.dispose();
  }

  /// 当科学计数法或小数精度变化时，重新换算当前金额。
  void _onConfigChanged() {
    final config = _configController.config;
    if (config.scientificNotation == _lastScientificNotation &&
        config.decimalPrecision == _lastDecimalPrecision) {
      _lastScientificNotation = config.scientificNotation;
      _lastDecimalPrecision = config.decimalPrecision;
      return;
    }
    _lastScientificNotation = config.scientificNotation;
    _lastDecimalPrecision = config.decimalPrecision;
    _recalculate();
  }

  String get fromCurrency => _fromCurrency;
  String get toCurrency => _toCurrency;
  String get amount => _amount;
  String get result => _result;
  ExchangeRateStatus get status => _status;
  String? get message => _message;

  ExchangeRateCache? get cache => _configController.config.exchangeRates;

  List<String> get currencies => _service.getCurrencies(cache);

  String get apiUrl => _configController.config.exchangeRateApiUrl;

  /// 设置源货币；切换时自动刷新该基准货币的汇率表。
  Future<void> setFromCurrency(String currency) async {
    if (_fromCurrency == currency) return;
    _fromCurrency = currency;
    _status = ExchangeRateStatus.loading;
    _message = null;
    notifyListeners();

    await refresh();
    _recalculate();
  }

  /// 设置目标货币；仅使用当前缓存汇率表计算，不重新请求。
  void setToCurrency(String currency) {
    if (_toCurrency == currency) return;
    _toCurrency = currency;
    _recalculate();
  }

  /// 交换源货币与目标货币，并刷新以新源货币为基准的汇率表。
  Future<void> swap() async {
    final oldFrom = _fromCurrency;
    final oldTo = _toCurrency;
    _fromCurrency = oldTo;
    _toCurrency = oldFrom;
    notifyListeners();

    await refresh();
    _recalculate();
  }

  /// 设置金额并实时换算。
  void setAmount(String value) {
    _amount = value;
    _recalculate();
  }

  /// 向当前金额追加数字或小数点。
  void append(String value) {
    if (value == '.') {
      if (_amount.contains('.')) return;
      if (_amount.isEmpty) {
        _amount = '0.';
      } else {
        _amount = '$_amount.';
      }
    } else {
      if (_amount == '0' && value != '.') {
        _amount = value;
      } else {
        _amount = '$_amount$value';
      }
    }
    _recalculate();
  }

  /// 删除当前金额末位。
  void backspace() {
    if (_amount.isEmpty) return;
    _amount = _amount.substring(0, _amount.length - 1);
    _recalculate();
  }

  /// 手动刷新汇率。
  Future<void> refresh() async {
    _status = ExchangeRateStatus.loading;
    _message = null;
    notifyListeners();

    final result = await _service.refresh(_fromCurrency, apiUrl, cache);

    _status = result.status;
    _message = result.message;

    if (result.cache != null) {
      await _configController.setExchangeRates(result.cache);
    }

    notifyListeners();
  }

  /// 清空金额。
  void clear() {
    _amount = '';
    _result = '';
    notifyListeners();
  }

  /// 将当前换算结果保存到历史记录。
  Future<void> saveToHistory() async {
    if (_amount.trim().isEmpty || _result.isEmpty || _result == 'Error') return;

    final record = CalculationHistory(
      expression: '$_amount $_fromCurrency → $_toCurrency',
      result: '$_result $_toCurrency',
      timestamp: DateTime.now().toUtc(),
      calculatorType: CalculatorType.exchangeRate,
      metadata: {
        'fromCurrency': _fromCurrency,
        'toCurrency': _toCurrency,
        'amount': _amount,
        'cacheBase': cache?.baseCurrency,
      },
    );
    await _configController.addHistory(record);
  }

  void _recalculate() {
    _result = '';

    if (_amount.trim().isEmpty) {
      notifyListeners();
      return;
    }

    final parsed = double.tryParse(_amount.replaceAll(',', ''));
    if (parsed == null) {
      _result = 'Error';
      notifyListeners();
      return;
    }

    final currentCache = cache;
    if (currentCache == null || currentCache.rates.isEmpty) {
      _result = '';
      notifyListeners();
      return;
    }

    final converted = _service.convert(parsed, _fromCurrency, _toCurrency, currentCache);
    if (converted == null) {
      _result = 'Error';
    } else {
      _result = _format(converted);
    }

    notifyListeners();
  }

  String _format(double value) {
    final config = _configController.config;
    return ScientificCalculatorService.formatResult(
      value,
      precision: config.decimalPrecision,
      scientificNotation: config.scientificNotation,
    );
  }
}
