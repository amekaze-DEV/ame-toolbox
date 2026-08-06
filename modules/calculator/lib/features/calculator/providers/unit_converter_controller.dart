import 'package:flutter/foundation.dart';

import '../models/calculation_history.dart';
import '../models/calculator_type.dart';
import '../models/unit_category.dart';
import '../services/unit_converter_service.dart';
import 'calculator_config_controller.dart';

/// 单位转换器状态控制器。
///
/// 持有当前类别、源单位、目标单位、源数值与换算结果，
/// 并在输入变化时实时计算目标数值。
class UnitConverterController extends ChangeNotifier {
  final UnitConverterService _service;
  final CalculatorConfigController _configController;

  UnitCategory _category = UnitCategory.length;
  String _fromUnit = 'm';
  String _toUnit = 'km';
  String _fromValue = '';
  String _result = '';
  String? _error;
  late bool _lastScientificNotation;
  late int _lastDecimalPrecision;

  UnitConverterController({
    required this._service,
    required this._configController,
  }) {
    _lastScientificNotation = _configController.config.scientificNotation;
    _lastDecimalPrecision = _configController.config.decimalPrecision;
    _configController.addListener(_onConfigChanged);
  }

  @override
  void dispose() {
    _configController.removeListener(_onConfigChanged);
    super.dispose();
  }

  /// 当科学计数法或小数精度变化时，重新换算当前源数值。
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

  UnitCategory get category => _category;
  String get fromUnit => _fromUnit;
  String get toUnit => _toUnit;
  String get fromValue => _fromValue;
  String get result => _result;
  String? get error => _error;

  List<String> get units => _service.getUnits(_category);

  /// 切换单位类别，并默认选中该类别第一个单位作为源与目标。
  void setCategory(UnitCategory category) {
    if (_category == category) return;
    _category = category;
    final defaultUnits = category.units;
    _fromUnit = defaultUnits.first;
    _toUnit = defaultUnits.length > 1 ? defaultUnits[1] : defaultUnits.first;
    _fromValue = '';
    _result = '';
    _error = null;
    notifyListeners();
  }

  /// 设置源单位并重新换算。
  void setFromUnit(String unit) {
    if (_fromUnit == unit) return;
    _fromUnit = unit;
    _recalculate();
  }

  /// 设置目标单位并重新换算。
  void setToUnit(String unit) {
    if (_toUnit == unit) return;
    _toUnit = unit;
    _recalculate();
  }

  /// 设置源数值并实时换算。
  void setFromValue(String value) {
    _fromValue = value;
    _recalculate();
  }

  /// 交换源与目标单位及数值。
  void swap() {
    final oldFrom = _fromUnit;
    _fromUnit = _toUnit;
    _toUnit = oldFrom;

    // 如果已有结果，把结果作为新的源数值。
    if (_result.isNotEmpty && _result != 'Error') {
      _fromValue = _result;
    }
    _recalculate();
  }

  void clear() {
    _fromValue = '';
    _result = '';
    _error = null;
    notifyListeners();
  }

  /// 将当前换算结果保存到历史记录。
  ///
  /// 仅在存在有效源数值与结果时写入；表达式格式为
  /// `1 m = 1000 mm`，结果格式为 `1000 mm`。
  Future<void> saveToHistory() async {
    if (_fromValue.trim().isEmpty || _result.isEmpty || _result == 'Error') {
      return;
    }

    final record = CalculationHistory(
      expression: '$_fromValue $_fromUnit = $_result $_toUnit',
      result: '$_result $_toUnit',
      timestamp: DateTime.now().toUtc(),
      calculatorType: CalculatorType.unitConverter,
      metadata: {
        'category': _category.value,
        'fromValue': _fromValue,
        'fromUnit': _fromUnit,
        'toUnit': _toUnit,
      },
    );
    await _configController.addHistory(record);
  }

  // ── 小键盘输入 ──

  /// 向源数值追加一位数字或小数点。
  void append(String value) {
    if (value == '±') {
      _toggleSign();
      return;
    }

    // 禁止多个小数点。
    if (value == '.' && _fromValue.contains('.')) return;

    // 禁止在空值时输入前导 00。
    if (value == '00' && _fromValue == '0') return;

    // 替换单独的前导 0。
    if (_fromValue == '0' && value != '.') {
      _fromValue = value;
    } else {
      _fromValue += value;
    }
    _recalculate();
  }

  /// 删除源数值最后一位。
  void backspace() {
    if (_fromValue.isEmpty) return;
    _fromValue = _fromValue.substring(0, _fromValue.length - 1);
    _recalculate();
  }

  void _toggleSign() {
    if (_fromValue.isEmpty || _fromValue == '0') {
      _fromValue = '-';
      notifyListeners();
      return;
    }

    if (_fromValue.startsWith('-')) {
      _fromValue = _fromValue.substring(1);
    } else {
      _fromValue = '-$_fromValue';
    }
    _recalculate();
  }

  void _recalculate() {
    _error = null;
    if (_fromValue.trim().isEmpty) {
      _result = '';
      notifyListeners();
      return;
    }

    final parsed = double.tryParse(_fromValue.replaceAll(',', ''));
    if (parsed == null) {
      _result = '';
      _error = '请输入有效数字';
      notifyListeners();
      return;
    }

    try {
      final converted = _service.convert(_category, _fromUnit, _toUnit, parsed);
      _result = _service.formatResult(
        converted,
        precision: _configController.config.decimalPrecision,
        scientificNotation: _configController.config.scientificNotation,
      );
    } on FormatException catch (e) {
      _result = 'Error';
      _error = e.message;
    }

    notifyListeners();
  }
}
