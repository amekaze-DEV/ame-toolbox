import 'package:flutter/foundation.dart';

import '../models/calculation_history.dart';
import '../models/calculator_config.dart';
import '../models/calculator_type.dart';
import '../services/scientific_calculator_service.dart';
import 'calculator_config_controller.dart';

/// 科学计算器状态控制器。
///
/// 持有当前表达式、计算结果、角度模式，并负责将成功计算写入历史记录。
class ScientificCalculatorController extends ChangeNotifier {
  final ScientificCalculatorService _service;
  final CalculatorConfigController _configController;

  String _expression = '';
  CalculationResult _result = const CalculationResult(display: '');
  bool _degrees = true; // DEG 为默认模式
  String? _lastResult;
  late CalculatorConfig _lastConfig;

  ScientificCalculatorController({
    required this._service,
    required this._configController,
  }) {
    _lastConfig = _configController.config;
    _configController.addListener(_onConfigChanged);
  }

  @override
  void dispose() {
    _configController.removeListener(_onConfigChanged);
    super.dispose();
  }

  /// 配置中的小数精度或科学计数法开关变化时，重新格式化当前结果。
  void _onConfigChanged() {
    final config = _configController.config;
    if (config.scientificNotation == _lastConfig.scientificNotation &&
        config.decimalPrecision == _lastConfig.decimalPrecision) {
      _lastConfig = config;
      return;
    }
    _lastConfig = config;

    if (_result.value != null && !_result.isError) {
      _result = CalculationResult(
        value: _result.value,
        display: ScientificCalculatorService.formatResult(
          _result.value!,
          precision: config.decimalPrecision,
          scientificNotation: config.scientificNotation,
        ),
      );
    }
    notifyListeners();
  }

  /// 当前输入表达式（界面显示字符串）。
  String get expression => _expression;

  /// 当前计算结果。
  CalculationResult get result => _result;

  /// 是否为角度模式（DEG），否则为弧度模式（RAD）。
  bool get degrees => _degrees;

  String get angleMode => _degrees ? 'DEG' : 'RAD';

  /// 上一次成功计算的结果字符串，供 `Ans` 使用。
  String? get lastResult => _lastResult;

  /// 当前配置中的历史记录列表。
  List<CalculationHistory> get history => _configController.config.history;

  /// 在表达式末尾追加内容。
  void append(String text) {
    if (text == 'Ans') {
      final ans = _lastResult ?? '0';
      _expression += ans;
    } else {
      _expression += text;
    }
    _recalculate();
  }

  /// 退格一次。
  void backspace() {
    if (_expression.isEmpty) return;
    _expression = _expression.substring(0, _expression.length - 1);
    _recalculate();
  }

  /// 清空表达式与当前结果。
  void clear() {
    _expression = '';
    _result = const CalculationResult(display: '');
    notifyListeners();
  }

  /// 直接设置表达式。
  void setExpression(String expression) {
    _expression = expression;
    _recalculate();
  }

  /// 切换 DEG / RAD。
  void toggleAngleMode() {
    _degrees = !_degrees;
    _recalculate();
  }

  void setAngleMode(bool degrees) {
    if (_degrees == degrees) return;
    _degrees = degrees;
    _recalculate();
  }

  /// 执行计算并保存历史记录。
  Future<void> calculate() async {
    if (_expression.trim().isEmpty) return;

    final config = _configController.config;
    _result = _service.evaluate(
      _expression,
      degrees: _degrees,
      precision: config.decimalPrecision,
      scientificNotation: config.scientificNotation,
    );

    if (!_result.isError && _result.value != null) {
      _lastResult = _result.display;
      final record = CalculationHistory(
        expression: _expression,
        result: _result.display,
        timestamp: DateTime.now().toUtc(),
        angleMode: angleMode,
        calculatorType: CalculatorType.scientific,
      );
      await _configController.addHistory(record);
      // 计算成功后清空输入栏，结果继续显示在当前结果区。
      _expression = '';
    }

    notifyListeners();
  }

  /// 从历史记录回填表达式。
  void useHistory(CalculationHistory record) {
    _expression = record.expression;
    _degrees = record.angleMode == 'DEG';
    _recalculate();
  }

  /// 从历史记录结果中提取数值并追加到当前表达式末尾。
  void appendNumericResult(String result) {
    final numeric = _extractNumericValue(result);
    if (numeric != null && numeric.isNotEmpty) {
      _expression += numeric;
      _recalculate();
    }
  }

  /// 从结果文本中提取第一个数值（支持小数、科学计数法、千分位）。
  String? _extractNumericValue(String result) {
    final match = RegExp(r'[+-]?\d{1,3}(,\d{3})*(\.\d+)?([eE][+-]?\d+)?|'
            r'[+-]?\d+(\.\d+)?([eE][+-]?\d+)?')
        .firstMatch(result);
    return match?.group(0)?.replaceAll(',', '');
  }

  /// 删除单条历史记录。
  Future<void> deleteHistoryRecord(CalculationHistory record) async {
    final newHistory = history.where((h) => h != record).toList();
    await _configController.setHistory(newHistory);
  }

  /// 清空全部历史记录。
  Future<void> clearHistory() async {
    await _configController.clearHistory();
  }

  void _recalculate() {
    if (_expression.trim().isEmpty) {
      _result = const CalculationResult(display: '');
    } else {
      final config = _configController.config;
      final result = _service.evaluate(
        _expression,
        degrees: _degrees,
        precision: config.decimalPrecision,
        scientificNotation: config.scientificNotation,
      );
      // 输入过程中仅展示成功求值的结果，未完成算式不显示 Error。
      _result = result.isError
          ? const CalculationResult(display: '')
          : result;
    }
    notifyListeners();
  }
}
