import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calculation_history.dart';
import '../models/calculator_type.dart';
import '../models/gas_type.dart';
import '../models/geometry_shape.dart';
import '../models/unit_category.dart';
import '../providers/calculator_config_provider.dart';
import '../providers/exchange_rate_provider.dart';
import '../providers/geometry_provider.dart';
import '../providers/radix_converter_provider.dart';
import '../providers/scientific_calculator_provider.dart';
import '../providers/standard_cubic_mass_controller.dart';
import '../providers/standard_cubic_mass_provider.dart';
import '../providers/unit_converter_provider.dart';
import '../services/radix_converter_service.dart';

/// 历史记录回填服务。
///
/// 将 [CalculationHistory] 中的参数回填到对应计算器的控制器，
/// 供历史详情页与横屏历史面板复用。
class HistoryBackfillService {
  const HistoryBackfillService._();

  /// 切换至记录对应的计算器类型并回填原始输入参数。
  static Future<void> backfillExpression(
    WidgetRef ref,
    CalculationHistory record,
  ) async {
    final configController = ref.read(calculatorConfigProvider);
    final type = record.calculatorType;
    await configController.setCurrentType(type);

    switch (type) {
      case CalculatorType.scientific:
        ref.read(scientificCalculatorProvider).useHistory(record);
      case CalculatorType.unitConverter:
        _backfillUnitConverter(ref, record);
      case CalculatorType.geometry:
        _backfillGeometry(ref, record);
      case CalculatorType.standardCubicToMass:
        _backfillStandardCubicMass(ref, record);
      case CalculatorType.radix:
        _backfillRadix(ref, record);
      case CalculatorType.exchangeRate:
        _backfillExchangeRate(ref, record);
    }
  }

  /// 从历史记录结果中提取数值并追加到当前计算器的输入中。
  static Future<void> backfillResult(
    WidgetRef ref,
    CalculationHistory record,
  ) async {
    final numeric = _extractNumericValue(record.result);
    if (numeric == null || numeric.isEmpty) return;

    final configController = ref.read(calculatorConfigProvider);
    final type = record.calculatorType;
    await configController.setCurrentType(type);

    switch (type) {
      case CalculatorType.scientific:
        ref.read(scientificCalculatorProvider).append(numeric);
      case CalculatorType.unitConverter:
        ref.read(unitConverterProvider).setFromValue(numeric);
      case CalculatorType.geometry:
        _backfillGeometryResult(ref, record, numeric);
      case CalculatorType.standardCubicToMass:
        _backfillStandardCubicMassResult(ref, record, numeric);
      case CalculatorType.radix:
        ref.read(radixConverterProvider).setValue(
              _activeRadixType(record),
              numeric,
            );
      case CalculatorType.exchangeRate:
        ref.read(exchangeRateProvider).setAmount(numeric);
    }
  }

  static void _backfillUnitConverter(WidgetRef ref, CalculationHistory record) {
    final metadata = record.metadata;
    if (metadata == null) return;

    final controller = ref.read(unitConverterProvider);
    final category = UnitCategoryExtension.fromString(
      metadata['category'] as String?,
    );
    controller.setCategory(category);
    controller.setFromUnit(metadata['fromUnit'] as String? ?? '');
    controller.setToUnit(metadata['toUnit'] as String? ?? '');
    controller.setFromValue(metadata['fromValue'] as String? ?? '');
  }

  static void _backfillGeometry(WidgetRef ref, CalculationHistory record) {
    final metadata = record.metadata;
    if (metadata == null) return;

    final controller = ref.read(geometryProvider);
    final shape = GeometryShapeExtension.fromString(
      metadata['shape'] as String?,
    );
    controller.setShape(shape);

    final inputUnits = metadata['inputUnits'];
    if (inputUnits is Map) {
      for (final entry in inputUnits.entries) {
        controller.setInputUnit(entry.key.toString(), entry.value.toString());
      }
    } else {
      final inputUnit = metadata['inputUnit'] as String?;
      if (inputUnit != null && inputUnit.isNotEmpty) {
        for (final field in controller.inputFields) {
          controller.setInputUnit(field, inputUnit);
        }
      }
    }

    final inputs = metadata['inputs'];
    if (inputs is Map) {
      for (final entry in inputs.entries) {
        controller.setInput(entry.key.toString(), entry.value.toString());
      }
    }

    final outputUnits = metadata['outputUnits'];
    if (outputUnits is Map) {
      for (final entry in outputUnits.entries) {
        controller.setOutputUnit(entry.key.toString(), entry.value.toString());
      }
    } else {
      final outputUnit = metadata['outputUnit'] as String?;
      if (outputUnit != null && outputUnit.isNotEmpty) {
        for (final name in controller.results.keys) {
          controller.setOutputUnit(name, outputUnit);
        }
      }
    }
  }

  static void _backfillGeometryResult(
    WidgetRef ref,
    CalculationHistory record,
    String numeric,
  ) {
    final controller = ref.read(geometryProvider);
    final fields = controller.inputFields;
    if (fields.isNotEmpty) {
      controller.setActiveField(fields.first);
      controller.setInput(fields.first, numeric);
    }
  }

  static void _backfillStandardCubicMass(
    WidgetRef ref,
    CalculationHistory record,
  ) {
    final metadata = record.metadata;
    if (metadata == null) return;

    final controller = ref.read(standardCubicMassProvider);
    final gasType = GasTypeExtension.fromString(
      metadata['gasType'] as String?,
    );
    controller.setGasType(gasType);
    controller.setCustomMolarMass(
      metadata['customMolarMass'] as String? ?? '',
    );
    controller.setVolumeUnit(metadata['volumeUnit'] as String? ?? 'Nm³');
    controller.setMassUnit(metadata['massUnit'] as String? ?? 'kg');

    final directionName = metadata['direction'] as String?;
    final direction = directionName ==
            StandardCubicMassDirection.massToVolume.name
        ? StandardCubicMassDirection.massToVolume
        : StandardCubicMassDirection.volumeToMass;
    controller.setDirection(direction);

    if (direction == StandardCubicMassDirection.massToVolume) {
      controller.setMassValue(metadata['massValue'] as String? ?? '');
    } else {
      controller.setVolumeValue(metadata['volumeValue'] as String? ?? '');
    }
  }

  static void _backfillStandardCubicMassResult(
    WidgetRef ref,
    CalculationHistory record,
    String numeric,
  ) {
    final controller = ref.read(standardCubicMassProvider);
    final directionName = record.metadata?['direction'] as String?;
    final direction = directionName ==
            StandardCubicMassDirection.massToVolume.name
        ? StandardCubicMassDirection.massToVolume
        : StandardCubicMassDirection.volumeToMass;

    if (direction == StandardCubicMassDirection.massToVolume) {
      controller.setVolumeValue(numeric);
    } else {
      controller.setMassValue(numeric);
    }
  }

  static void _backfillRadix(WidgetRef ref, CalculationHistory record) {
    final metadata = record.metadata;
    if (metadata == null) return;

    final controller = ref.read(radixConverterProvider);
    final values = metadata['values'];
    if (values is Map) {
      for (final entry in values.entries) {
        controller.setValue(
          RadixType.fromString(entry.key.toString()),
          entry.value.toString(),
        );
      }
    }
  }

  static void _backfillExchangeRate(WidgetRef ref, CalculationHistory record) {
    final metadata = record.metadata;
    if (metadata == null) return;

    final controller = ref.read(exchangeRateProvider);
    final fromCurrency = metadata['fromCurrency'] as String?;
    final toCurrency = metadata['toCurrency'] as String?;
    final amount = metadata['amount'] as String?;
    if (fromCurrency != null && fromCurrency.isNotEmpty) {
      controller.setFromCurrency(fromCurrency);
    }
    if (toCurrency != null && toCurrency.isNotEmpty) {
      controller.setToCurrency(toCurrency);
    }
    if (amount != null && amount.isNotEmpty) {
      controller.setAmount(amount);
    }
  }

  static RadixType _activeRadixType(CalculationHistory record) {
    final metadata = record.metadata;
    if (metadata == null) return RadixType.decimal;
    return RadixType.fromString(metadata['activeType'] as String?);
  }

  /// 从结果文本中提取第一个数值（支持小数、科学计数法、千分位）。
  static String? _extractNumericValue(String result) {
    final match = RegExp(
            r'[+-]?\d{1,3}(,\d{3})*(\.\d+)?([eE][+-]?\d+)?|'
            r'[+-]?\d+(\.\d+)?([eE][+-]?\d+)?')
        .firstMatch(result);
    return match?.group(0)?.replaceAll(',', '');
  }
}
