import 'package:flutter/foundation.dart';

import '../models/calculation_history.dart';
import '../models/calculator_type.dart';
import '../services/radix_converter_service.dart';
import 'calculator_config_controller.dart';

/// 进制转换器状态控制器。
///
/// 管理四个进制输入框的实时同步。
class RadixConverterController extends ChangeNotifier {
  final RadixConverterService _service;
  final CalculatorConfigController _configController;

  final Map<RadixType, String> _values = {
    RadixType.binary: '',
    RadixType.octal: '',
    RadixType.decimal: '',
    RadixType.hex: '',
  };

  RadixType _activeType = RadixType.decimal;
  String? _hint;

  RadixConverterController({
    required this._service,
    required this._configController,
  });

  Map<RadixType, String> get values => Map.unmodifiable(_values);
  RadixType get activeType => _activeType;
  String? get hint => _hint;

  /// 设置当前活跃进制输入框。
  void setActiveType(RadixType type) {
    if (_activeType == type) return;
    _activeType = type;
    notifyListeners();
  }

  /// 设置指定进制的输入值，并同步更新其他进制。
  void setValue(RadixType type, String value) {
    _hint = null;
    _activeType = type;

    if (value.trim().isEmpty) {
      _clearAll();
      return;
    }

    _values[type] = value;

    // 同步其他进制。
    for (final target in RadixType.values) {
      if (target == type) continue;
      _values[target] = _service.convert(
        value,
        type,
        target,
        onHint: target == RadixType.binary ? (hint) => _hint = hint : null,
      );
    }

    notifyListeners();
  }

  /// 清空所有进制输入。
  void clear() {
    _hint = null;
    _clearAll();
  }

  void _clearAll() {
    for (final key in _values.keys) {
      _values[key] = '';
    }
    notifyListeners();
  }

  /// 向当前活跃进制输入框追加一个字符。
  void append(String value) {
    final current = _rawValue(_activeType);
    final newValue = current + value;
    final formatted = _service.convert(newValue, _activeType, _activeType);
    setValue(_activeType, formatted);
  }

  /// 删除当前活跃进制输入框的最后一位。
  void backspace() {
    final current = _rawValue(_activeType);
    if (current.isEmpty) return;

    final newValue = current.substring(0, current.length - 1);
    if (newValue.isEmpty) {
      clear();
      return;
    }

    final formatted = _service.convert(newValue, _activeType, _activeType);
    setValue(_activeType, formatted);
  }

  /// 切换当前活跃十进制输入框的正负号。
  ///
  /// 仅十进制支持负数，其他进制调用此方法无效。
  void toggleSign() {
    if (_activeType != RadixType.decimal) return;

    final current = _values[_activeType] ?? '';
    if (current.isEmpty) return;

    if (current.startsWith('-')) {
      setValue(_activeType, current.substring(1));
    } else {
      setValue(_activeType, '-$current');
    }
  }

  /// 获取去除进制前缀后的原始输入内容。
  String _rawValue(RadixType type) {
    final value = _values[type] ?? '';
    final prefix = type.prefix;
    if (prefix.isNotEmpty && value.startsWith(prefix)) {
      return value.substring(prefix.length);
    }
    return value;
  }

  /// 将当前结果保存到历史记录。
  Future<void> saveToHistory() async {
    final activeValue = _values[_activeType];
    if (activeValue == null || activeValue.trim().isEmpty) return;

    final others = <String>[];
    for (final type in RadixType.values) {
      if (type == _activeType) continue;
      final v = _values[type];
      if (v != null && v.isNotEmpty) {
        others.add('${type.displayName}: $v');
      }
    }

    final record = CalculationHistory(
      expression: '${_activeType.displayName}: $activeValue',
      result: others.join('; '),
      timestamp: DateTime.now().toUtc(),
      calculatorType: CalculatorType.radix,
      metadata: {
        'activeType': _activeType.value,
        'values': _values.map((type, value) => MapEntry(type.value, value)),
      },
    );
    await _configController.addHistory(record);
  }
}
