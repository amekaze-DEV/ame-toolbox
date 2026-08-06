import 'package:flutter/foundation.dart';

import '../models/calculator_type.dart';
import '../models/calculation_history.dart';
import '../models/gas_type.dart';
import '../services/scientific_calculator_service.dart';
import '../services/standard_cubic_mass_service.dart';
import 'calculator_config_controller.dart';

/// 标准立方米-质量转换方向。
enum StandardCubicMassDirection {
  /// 从标准体积转换到质量。
  volumeToMass,

  /// 从质量转换到标准体积。
  massToVolume,
}

/// 标准立方米-质量转换控制器。
///
/// 支持气体类型选择、自定义摩尔质量、
/// 标准体积与质量双向实时换算。
class StandardCubicMassController extends ChangeNotifier {
  final StandardCubicMassService _service;
  final CalculatorConfigController _configController;

  GasType _gasType = GasType.naturalGas;
  String _customMolarMass = '';

  String _volumeValue = '';
  String _volumeUnit = 'Nm³';
  String _massValue = '';
  String _massUnit = 'kg';

  /// 当前转换方向。
  StandardCubicMassDirection _direction = StandardCubicMassDirection.volumeToMass;

  /// 当前被小键盘控制的字段。
  String _activeField = 'volume';

  String? _error;
  String _density = '';
  late bool _lastScientificNotation;
  late int _lastDecimalPrecision;

  StandardCubicMassController({
    required this._service,
    required this._configController,
  }) {
    _lastScientificNotation = _configController.config.scientificNotation;
    _lastDecimalPrecision = _configController.config.decimalPrecision;
    _configController.addListener(_onConfigChanged);
    _updateDensity();
  }

  @override
  void dispose() {
    _configController.removeListener(_onConfigChanged);
    super.dispose();
  }

  /// 当科学计数法或小数精度变化时，重新计算密度与当前换算结果。
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
    _updateDensity();
    _recalculate();
  }

  GasType get gasType => _gasType;
  String get customMolarMass => _customMolarMass;
  String get volumeValue => _volumeValue;
  String get volumeUnit => _volumeUnit;
  String get massValue => _massValue;
  String get massUnit => _massUnit;
  StandardCubicMassDirection get direction => _direction;
  String? get error => _error;
  String get density => _density;
  String get activeField => _activeField;

  /// 标准摩尔体积（L/mol），固定为 22.414。
  String get vm => '22.414';

  bool get isCustom => _gasType == GasType.custom;

  List<String> get editableFields => [
        'volume',
        'mass',
        if (isCustom) 'customMolarMass',
      ];

  /// 当前有效摩尔质量（g/mol）。
  double? get _effectiveMolarMass {
    if (_gasType == GasType.custom) {
      final parsed = double.tryParse(_customMolarMass);
      return parsed;
    }
    return _service.resolveMolarMass(_gasType);
  }

  /// 当前有效标准摩尔体积（L/mol），固定为 22.414。
  double? get _effectiveVm => 22.414;

  void setGasType(GasType type) {
    if (_gasType == type) return;
    _gasType = type;
    if (type != GasType.custom) {
      _customMolarMass = '';
    }
    _updateDensity();
    _recalculate();
  }

  void setDirection(StandardCubicMassDirection direction) {
    if (_direction == direction) return;
    _direction = direction;
    _activeField = direction == StandardCubicMassDirection.volumeToMass ? 'volume' : 'mass';
    _recalculate();
  }

  void swapDirection() {
    setDirection(
      _direction == StandardCubicMassDirection.volumeToMass
          ? StandardCubicMassDirection.massToVolume
          : StandardCubicMassDirection.volumeToMass,
    );
  }

  void setActiveField(String field) {
    if (_activeField == field) return;
    _activeField = field;
    notifyListeners();
  }

  void setCustomMolarMass(String value) {
    if (_gasType != GasType.custom && value.isNotEmpty) {
      // 用户在非自定义气体下手动编辑摩尔质量时，自动切换为自定义类型，
      // 避免用户误以为覆盖了内置物质的默认摩尔质量。
      _gasType = GasType.custom;
    }
    _customMolarMass = value;
    _activeField = 'customMolarMass';
    _updateDensity();
    _recalculate();
  }

  void setVolumeValue(String value) {
    _volumeValue = value;
    if (_direction == StandardCubicMassDirection.massToVolume) {
      // 当前处于质量->体积模式，用户直接编辑体积字段时切换方向。
      _direction = StandardCubicMassDirection.volumeToMass;
    }
    _activeField = 'volume';
    _recalculate();
  }

  void setVolumeUnit(String unit) {
    if (_volumeUnit == unit) return;
    _volumeUnit = unit;
    _recalculate();
  }

  void setMassValue(String value) {
    _massValue = value;
    if (_direction == StandardCubicMassDirection.volumeToMass) {
      // 当前处于体积->质量模式，用户直接编辑质量字段时切换方向。
      _direction = StandardCubicMassDirection.massToVolume;
    }
    _activeField = 'mass';
    _recalculate();
  }

  void setMassUnit(String unit) {
    if (_massUnit == unit) return;
    _massUnit = unit;
    _recalculate();
  }

  void clear() {
    _volumeValue = '';
    _massValue = '';
    _customMolarMass = '';
    _direction = StandardCubicMassDirection.volumeToMass;
    _error = null;
    _activeField = 'volume';
    notifyListeners();
  }

  // ── 小键盘输入 ──

  /// 向当前活跃字段追加一位数字或小数点。
  void append(String value) {
    if (!editableFields.contains(_activeField)) return;

    var current = _fieldValue(_activeField);

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

    _setFieldValue(_activeField, current);
  }

  /// 删除当前活跃字段输入的最后一位。
  void backspace() {
    if (!editableFields.contains(_activeField)) return;

    var current = _fieldValue(_activeField);
    if (current.isEmpty) return;

    if (current.length <= 1) {
      current = '';
    } else {
      current = current.substring(0, current.length - 1);
    }

    _setFieldValue(_activeField, current);
  }

  String _fieldValue(String field) {
    return switch (field) {
      'volume' => _volumeValue,
      'mass' => _massValue,
      'customMolarMass' => _customMolarMass,
      _ => '',
    };
  }

  void _setFieldValue(String field, String value) {
    switch (field) {
      case 'volume':
        setVolumeValue(value);
      case 'mass':
        setMassValue(value);
      case 'customMolarMass':
        setCustomMolarMass(value);
    }
  }

  void _updateDensity() {
    final m = _effectiveMolarMass;
    final vm = _effectiveVm;
    if (m == null || vm == null || m <= 0 || vm <= 0) {
      _density = '';
    } else {
      final density = _service.calculateDensity(m, vm);
      _density = _format(density);
    }
    notifyListeners();
  }

  void _recalculate() {
    if (_direction == StandardCubicMassDirection.volumeToMass) {
      _calculateMassFromVolume();
    } else {
      _calculateVolumeFromMass();
    }
  }

  void _calculateMassFromVolume() {
    _error = null;
    if (_volumeValue.trim().isEmpty) {
      _massValue = '';
      notifyListeners();
      return;
    }

    final volume = double.tryParse(_volumeValue.replaceAll(',', ''));
    final m = _effectiveMolarMass;
    final vm = _effectiveVm;

    if (volume == null) {
      _error = '请输入有效数字';
      notifyListeners();
      return;
    }
    if (m == null) {
      _error = '请输入有效摩尔质量';
      notifyListeners();
      return;
    }
    if (vm == null) {
      _error = '请输入有效标准摩尔体积';
      notifyListeners();
      return;
    }

    try {
      final mass = _service.calculateMass(volume, _volumeUnit, m, vm);
      _massValue = _format(mass);
    } on ArgumentError catch (e) {
      _error = e.message?.toString();
    }

    notifyListeners();
  }

  void _calculateVolumeFromMass() {
    _error = null;
    if (_massValue.trim().isEmpty) {
      _volumeValue = '';
      notifyListeners();
      return;
    }

    final mass = double.tryParse(_massValue.replaceAll(',', ''));
    final m = _effectiveMolarMass;
    final vm = _effectiveVm;

    if (mass == null) {
      _error = '请输入有效数字';
      notifyListeners();
      return;
    }
    if (m == null) {
      _error = '请输入有效摩尔质量';
      notifyListeners();
      return;
    }
    if (vm == null) {
      _error = '请输入有效标准摩尔体积';
      notifyListeners();
      return;
    }

    try {
      final volume = _service.calculateVolume(mass, _massUnit, m, vm);
      _volumeValue = _format(volume);
    } on ArgumentError catch (e) {
      _error = e.message?.toString();
    }

    notifyListeners();
  }

  Future<void> saveToHistory() async {
    final fromVolume = _direction == StandardCubicMassDirection.volumeToMass;
    final expression = fromVolume
        ? '${_gasType.displayName} $_volumeValue $_volumeUnit → $_massUnit'
        : '${_gasType.displayName} $_massValue $_massUnit → $_volumeUnit';
    final result = fromVolume
        ? '$_massValue $_massUnit'
        : '$_volumeValue $_volumeUnit';

    await _configController.addHistory(CalculationHistory(
      expression: expression,
      result: result,
      timestamp: DateTime.now().toUtc(),
      calculatorType: CalculatorType.standardCubicToMass,
      metadata: {
        'gasType': _gasType.value,
        'customMolarMass': _customMolarMass,
        'vm': '22.414',
        'volumeValue': _volumeValue,
        'volumeUnit': _volumeUnit,
        'massValue': _massValue,
        'massUnit': _massUnit,
        'direction': _direction.name,
      },
    ));
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
