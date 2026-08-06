import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';
import 'package:intl/intl.dart';

import '../models/calculation_history.dart';
import '../models/calculator_type.dart';
import '../models/gas_type.dart';
import '../models/geometry_shape.dart';
import '../models/unit_category.dart';
import '../providers/calculator_config_provider.dart';
import '../providers/geometry_provider.dart';
import '../providers/scientific_calculator_provider.dart';
import '../providers/standard_cubic_mass_controller.dart';
import '../providers/standard_cubic_mass_provider.dart';
import '../providers/unit_converter_provider.dart';

/// 多功能计算器历史详情页。
///
/// 竖屏全屏显示，支持：
/// - 输入/输出分区展示
/// - 返回按钮：切换至对应计算器并回填原始算式
/// - 复制按钮：弹出「回填结果 / 复制结果 / 导出计算」选项
/// - 长按/右键删除单条、顶部清空全部
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configController = ref.watch(calculatorConfigProvider);
    final history = configController.config.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('计算历史'),
        centerTitle: true,
        actions: [
          if (history.isNotEmpty)
            AdaptiveButton(
              variant: AdaptiveButtonVariant.text,
              label: '清空',
              onPressed: () => _showClearConfirm(context, ref),
            ),
        ],
      ),
      body: history.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: history.length,
          separatorBuilder: (_, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
                final record = history[index];
                return _HistoryItem(
                  record: record,
                  onBackfillExpression: () =>
                      _backfillExpression(context, ref, record),
                  onBackfillResult: () =>
                      _backfillResult(context, ref, record),
                  onCopy: (text) => _copyToClipboard(context, text),
                  onDelete: () => configController.setHistory(
                    history.where((h) => h != record).toList(),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无计算记录',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 返回对应模块并回填原始算式。
  Future<void> _backfillExpression(
    BuildContext context,
    WidgetRef ref,
    CalculationHistory record,
  ) async {
    final configController = ref.read(calculatorConfigProvider);
    await configController.setCurrentType(record.calculatorType);

    switch (record.calculatorType) {
      case CalculatorType.scientific:
        ref.read(scientificCalculatorProvider).useHistory(record);
      case CalculatorType.unitConverter:
        _backfillUnitConverter(ref, record);
      case CalculatorType.geometry:
        _backfillGeometry(ref, record);
      case CalculatorType.standardCubicToMass:
        _backfillStandardCubicMass(ref, record);
      case CalculatorType.radix:
      case CalculatorType.exchangeRate:
        break;
    }

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// 返回对应模块并回填结果数值。
  Future<void> _backfillResult(
    BuildContext context,
    WidgetRef ref,
    CalculationHistory record,
  ) async {
    final numeric = _extractNumericValue(record.result);
    if (numeric == null || numeric.isEmpty) return;

    final configController = ref.read(calculatorConfigProvider);
    await configController.setCurrentType(record.calculatorType);

    switch (record.calculatorType) {
      case CalculatorType.scientific:
        ref.read(scientificCalculatorProvider).append(numeric);
      case CalculatorType.unitConverter:
        ref.read(unitConverterProvider).setFromValue(numeric);
      case CalculatorType.geometry:
        _backfillGeometryResult(ref, record, numeric);
      case CalculatorType.standardCubicToMass:
        _backfillStandardCubicMassResult(ref, record, numeric);
      case CalculatorType.radix:
      case CalculatorType.exchangeRate:
        break;
    }

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  void _backfillUnitConverter(WidgetRef ref, CalculationHistory record) {
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

  void _backfillGeometry(WidgetRef ref, CalculationHistory record) {
    final metadata = record.metadata;
    if (metadata == null) return;

    final controller = ref.read(geometryProvider);
    final shape = GeometryShapeExtension.fromString(
      metadata['shape'] as String?,
    );
    controller.setShape(shape);

    // 优先读取按字段存储的输入单位；兼容旧版单 inputUnit 字段。
    final inputUnits = metadata['inputUnits'];
    if (inputUnits is Map) {
      for (final entry in inputUnits.entries) {
        controller.setInputUnit(
          entry.key.toString(),
          entry.value.toString(),
        );
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

    // 输入回填完成并计算后，再恢复输出单位。
    // 优先读取按结果存储的输出单位；兼容旧版单 outputUnit 字段。
    final outputUnits = metadata['outputUnits'];
    if (outputUnits is Map) {
      for (final entry in outputUnits.entries) {
        controller.setOutputUnit(
          entry.key.toString(),
          entry.value.toString(),
        );
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

  void _backfillGeometryResult(
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

  void _backfillStandardCubicMass(WidgetRef ref, CalculationHistory record) {
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
    final direction = directionName == StandardCubicMassDirection.massToVolume.name
        ? StandardCubicMassDirection.massToVolume
        : StandardCubicMassDirection.volumeToMass;
    controller.setDirection(direction);

    if (direction == StandardCubicMassDirection.massToVolume) {
      controller.setMassValue(metadata['massValue'] as String? ?? '');
    } else {
      controller.setVolumeValue(metadata['volumeValue'] as String? ?? '');
    }
  }

  void _backfillStandardCubicMassResult(
    WidgetRef ref,
    CalculationHistory record,
    String numeric,
  ) {
    final controller = ref.read(standardCubicMassProvider);
    final directionName = record.metadata?['direction'] as String?;
    final direction = directionName == StandardCubicMassDirection.massToVolume.name
        ? StandardCubicMassDirection.massToVolume
        : StandardCubicMassDirection.volumeToMass;

    if (direction == StandardCubicMassDirection.massToVolume) {
      controller.setVolumeValue(numeric);
    } else {
      controller.setMassValue(numeric);
    }
  }

  /// 从结果文本中提取第一个数值（支持小数、科学计数法、千分位）。
  String? _extractNumericValue(String result) {
    final match = RegExp(r'[+-]?\d{1,3}(,\d{3})*(\.\d+)?([eE][+-]?\d+)?|'
            r'[+-]?\d+(\.\d+)?([eE][+-]?\d+)?')
        .firstMatch(result);
    return match?.group(0)?.replaceAll(',', '');
  }

  /// 复制文本到剪贴板并提示。
  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制到剪贴板')),
      );
    }
  }

  Future<void> _showClearConfirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史'),
        content: const Text('确定要清空所有计算历史吗？此操作不可恢复。'),
        actions: [
          AdaptiveButton(
            variant: AdaptiveButtonVariant.text,
            label: '取消',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AdaptiveButton(
            variant: AdaptiveButtonVariant.text,
            label: '清空',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(calculatorConfigProvider).clearHistory();
    }
  }
}

class _HistoryItem extends StatelessWidget {
  final CalculationHistory record;
  final VoidCallback onBackfillExpression;
  final VoidCallback onBackfillResult;
  final ValueChanged<String> onCopy;
  final VoidCallback onDelete;

  const _HistoryItem({
    required this.record,
    required this.onBackfillExpression,
    required this.onBackfillResult,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeText =
        DateFormat('MM-dd HH:mm').format(record.timestamp.toLocal());

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 输入行：输入描述 + 返回按钮
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.expression,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AdaptiveIconButton(
                    icon: const Icon(Icons.reply),
                    tooltip: '返回模块回填算式',
                    onPressed: onBackfillExpression,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // 输出行：结果 + 复制按钮
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.result,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _CopyMenu(
                    record: record,
                    onBackfillResult: onBackfillResult,
                    onCopy: onCopy,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 元信息行：时间 + 计算器类型
              Row(
                children: [
                  Text(
                    timeText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(type: record.calculatorType),
                  if (record.calculatorType == CalculatorType.scientific) ...[
                    const SizedBox(width: 8),
                    Text(
                      record.angleMode,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 复制选项弹出菜单。
class _CopyMenu extends StatelessWidget {
  final CalculationHistory record;
  final VoidCallback onBackfillResult;
  final ValueChanged<String> onCopy;

  const _CopyMenu({
    required this.record,
    required this.onBackfillResult,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_CopyAction>(
      icon: const Icon(Icons.copy_outlined),
      tooltip: '复制选项',
      onSelected: (action) {
        switch (action) {
          case _CopyAction.backfill:
            onBackfillResult();
            break;
          case _CopyAction.result:
            onCopy(record.result);
            break;
          case _CopyAction.full:
            onCopy('${record.expression} = ${record.result}');
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _CopyAction.backfill,
          child: _MenuItem(
            icon: Icons.input,
            text: '回填结果',
          ),
        ),
        const PopupMenuItem(
          value: _CopyAction.result,
          child: _MenuItem(
            icon: Icons.copy,
            text: '复制结果',
          ),
        ),
        const PopupMenuItem(
          value: _CopyAction.full,
          child: _MenuItem(
            icon: Icons.ios_share,
            text: '导出计算',
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MenuItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurface),
        const SizedBox(width: 12),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final CalculatorType type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(type.displayName),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

enum _CopyAction {
  backfill,
  result,
  full,
}
