import 'package:flutter/foundation.dart';

import '../models/calculation_history.dart';
import '../models/calculator_type.dart';
import '../models/geometry_shape.dart';
import '../models/unit_category.dart';
import '../services/geometry_service.dart';
import '../services/unit_converter_service.dart';
import 'calculator_config_controller.dart';

/// 几何计算器状态控制器。
///
/// 持有当前几何体、各参数字符串输入与计算结果，
/// 输入变化时即时校验并计算所有可计算量。
/// 支持输入/输出单位选择，结果按输出单位展示。
class GeometryController extends ChangeNotifier {
  final GeometryService _service;
  final UnitConverterService _unitService;
  final CalculatorConfigController _configController;

  GeometryShape _shape = GeometryShape.circle;
  final Map<String, String> _inputs = {};
  Map<String, String> _results = {};
  String? _error;
  String _activeField = '';

  /// 各输入字段对应的单位（长度），未指定时默认为 m。
  final Map<String, String> _inputUnits = {};

  /// 各输出结果对应的单位，未指定时按结果维度使用默认单位。
  final Map<String, String> _outputUnits = {};

  late bool _lastScientificNotation;
  late int _lastDecimalPrecision;

  GeometryController({
    required this._service,
    required this._unitService,
    required this._configController,
  })  : _activeField = _service.getInputFields(GeometryShape.circle).isNotEmpty
            ? _service.getInputFields(GeometryShape.circle).first
            : '' {
    _lastScientificNotation = _configController.config.scientificNotation;
    _lastDecimalPrecision = _configController.config.decimalPrecision;
    _configController.addListener(_onConfigChanged);
  }

  @override
  void dispose() {
    _configController.removeListener(_onConfigChanged);
    super.dispose();
  }

  /// 当科学计数法或小数精度变化时，重新计算当前几何体结果。
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

  GeometryShape get shape => _shape;
  Map<String, String> get inputs => Map.unmodifiable(_inputs);
  Map<String, String> get results => Map.unmodifiable(_results);
  String? get error => _error;
  String get activeField => _activeField;

  /// 返回 [field] 对应的输入单位；未指定时返回 m。
  String inputUnit(String field) => _inputUnits[field] ?? 'm';

  /// 返回 [resultName] 对应的输出单位；未指定时返回该结果维度的默认单位。
  String outputUnit(String resultName) =>
      _outputUnits[resultName] ?? _defaultOutputUnitFor(resultName);

  GeometryService get service => _service;
  List<String> get inputFields => _service.getInputFields(_shape);
  String get formulaDescription => _service.getFormulaDescription(_shape);

  /// 切换几何体并清空输入与结果，同时重置为默认单位。
  void setShape(GeometryShape shape) {
    if (_shape == shape) return;
    _shape = shape;
    _inputs.clear();
    _results.clear();
    _error = null;
    _activeField = inputFields.isNotEmpty ? inputFields.first : '';
    _resetUnitsToDefaults();
    notifyListeners();
  }

  /// 设置当前活跃输入字段。
  void setActiveField(String field) {
    if (_activeField == field) return;
    _activeField = field;
    notifyListeners();
  }

  /// 设置指定字段的输入值并重新计算。
  void setInput(String field, String value) {
    if (value.isEmpty) {
      _inputs.remove(field);
    } else {
      _inputs[field] = value;
    }
    _activeField = field;
    _recalculate();
  }

  /// 设置 [field] 的输入单位。
  void setInputUnit(String field, String unit) {
    if (inputUnit(field) == unit) return;
    _inputUnits[field] = unit;
    _recalculate();
  }

  /// 设置 [resultName] 的输出单位。
  void setOutputUnit(String resultName, String unit) {
    if (outputUnit(resultName) == unit) return;
    _outputUnits[resultName] = unit;
    _recalculate();
  }

  void clear() {
    _inputs.clear();
    _results.clear();
    _error = null;
    _activeField = '';
    notifyListeners();
  }

  /// 将当前计算结果保存到历史记录。
  Future<void> saveToHistory() async {
    if (_results.isEmpty || _error != null) return;

    final record = CalculationHistory(
      expression:
          '${_shape.displayName}: ${_inputs.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
      result: _results.entries.map((e) => '${e.key}: ${e.value}').join('; '),
      timestamp: DateTime.now().toUtc(),
      calculatorType: CalculatorType.geometry,
      metadata: {
        'shape': _shape.value,
        'inputs': Map<String, String>.from(_inputs),
        'inputUnits': Map<String, String>.from(_inputUnits),
        'outputUnits': Map<String, String>.from(_outputUnits),
      },
    );
    await _configController.addHistory(record);
  }

  // ── 小键盘输入 ──

  /// 向当前活跃字段追加一位数字或小数点。
  void append(String value) {
    if (_activeField.isEmpty || !inputFields.contains(_activeField)) {
      return;
    }

    var current = _inputs[_activeField] ?? '';

    // 禁止多个小数点。
    if (value == '.' && current.contains('.')) return;

    // 禁止在空值时输入前导 00。
    if (value == '00' && current == '0') return;

    // 替换单独的前导 0。
    if (current == '0' && value != '.') {
      current = value;
    } else {
      current += value;
    }

    _inputs[_activeField] = current;
    _recalculate();
  }

  /// 删除当前活跃字段输入的最后一位。
  void backspace() {
    if (_activeField.isEmpty || !_inputs.containsKey(_activeField)) return;

    final current = _inputs[_activeField]!;
    if (current.length <= 1) {
      _inputs.remove(_activeField);
    } else {
      _inputs[_activeField] = current.substring(0, current.length - 1);
    }
    _recalculate();
  }

  void _recalculate() {
    _error = null;
    _results = {};

    final fields = inputFields;
    // 圆锥：r、h、l 中任意两个有值即可计算。
    final presentFields =
        fields.where((f) => _inputs.containsKey(f) && _inputs[f]!.isNotEmpty).toList();
    final isCone = _shape == GeometryShape.cone;
    final readyToCalculate = isCone
        ? presentFields.length >= 2
        : fields.every((f) => _inputs.containsKey(f) && _inputs[f]!.isNotEmpty);
    if (!readyToCalculate) {
      notifyListeners();
      return;
    }

    final parsed = <String, double>{};
    for (final field in fields) {
      final text = _inputs[field];
      if (text == null || text.isEmpty) {
        // 圆锥允许第三个字段为空，由 service 自动推导。
        if (isCone) continue;
        notifyListeners();
        return;
      }
      final value = double.tryParse(text.replaceAll(',', ''));
      if (value == null) {
        _error = '请输入有效数字';
        notifyListeners();
        return;
      }
      parsed[field] = _convertInputToBase(field, value);
    }

    final result = _service.calculate(_shape, parsed);
    if (result.isError) {
      _error = result.error;
    } else {
      final precision = _configController.config.decimalPrecision;
      _results = result.results.map((name, value) {
        final converted = _convertResultToOutputUnit(name, value);
        return MapEntry(
          name,
          _format(converted, precision),
        );
      });
    }

    notifyListeners();
  }

  /// 将 [resultName] 对应的 [baseValue] 从基准单位转换到其输出单位。
  ///
  /// 基准单位为 SI：长度 m、面积 m²、体积 m³。
  /// 结果名中包含“面积”或“表面积”等按面积维度转换；
  /// 包含“体积”按体积维度转换；
  /// 其他（长度、周长、对角线、母线等）按长度维度转换。
  double _convertResultToOutputUnit(String resultName, double baseValue) {
    final targetUnit = outputUnit(resultName);
    if (resultName.contains('体积')) {
      return _unitService.convert(UnitCategory.volume, 'm³', targetUnit, baseValue);
    }
    if (resultName.contains('面积')) {
      // 输出单位维度需为面积；若当前输出单位为长度或体积，则回退到 m²。
      final effectiveAreaUnit = _isAreaUnit(targetUnit) ? targetUnit : 'm²';
      return _unitService.convert(UnitCategory.area, 'm²', effectiveAreaUnit, baseValue);
    }
    // 长度类量。
    final effectiveLengthUnit = _isLengthUnit(targetUnit) ? targetUnit : 'm';
    return _unitService.convert(UnitCategory.length, 'm', effectiveLengthUnit, baseValue);
  }

  bool _isAreaUnit(String unit) =>
      UnitCategory.area.units.contains(unit);

  bool _isLengthUnit(String unit) =>
      UnitCategory.length.units.contains(unit);

  /// 将 [field] 的 [inputValue] 从其输入单位转换到基准单位 m。
  ///
  /// 输入参数均为长度量（半径、边长、高等）。
  double _convertInputToBase(String field, double inputValue) {
    final unit = _inputUnits[field] ?? 'm';
    return _unitService.convert(UnitCategory.length, unit, 'm', inputValue);
  }

  /// 根据当前几何体维度重置默认输入/输出单位。
  void _resetUnitsToDefaults() {
    _inputUnits.clear();
    _outputUnits.clear();
  }

  /// 返回当前几何体可选择的输入单位列表。
  List<String> get inputUnits => UnitCategory.length.units;

  /// 返回 [resultName] 可选择的输出单位列表。
  List<String> outputUnits(String resultName) {
    return _unitCategoryFor(resultName).units;
  }

  /// 返回 [resultName] 维度的默认输出单位（SI 基准单位）。
  static String _defaultOutputUnitFor(String resultName) {
    if (resultName.contains('体积')) return 'm³';
    if (resultName.contains('面积')) return 'm²';
    return 'm';
  }

  /// 根据结果名称判断其单位维度类别。
  static UnitCategory _unitCategoryFor(String resultName) {
    if (resultName.contains('体积')) return UnitCategory.volume;
    if (resultName.contains('面积')) return UnitCategory.area;
    return UnitCategory.length;
  }

  String _format(double value, int precision) {
    return _unitService.formatResult(
      value,
      precision: precision,
      scientificNotation: _configController.config.scientificNotation,
    );
  }

  static double precisionFactor(int precision) {
    var factor = 1.0;
    for (var i = 0; i < precision; i++) {
      factor *= 10;
    }
    return factor;
  }
}
