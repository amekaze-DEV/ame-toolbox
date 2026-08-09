import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/geometry_shape.dart';
import '../models/unit_category.dart';
import '../providers/calculator_config_provider.dart';
import '../providers/geometry_controller.dart';
import '../providers/geometry_provider.dart';
import '../widgets/numeric_keypad.dart';

/// 几何计算器页面。
///
/// 顶部选择几何体，动态显示输入字段与输入/输出单位选择，下方展示结果卡片与公式说明。
class GeometryPage extends ConsumerWidget {
  const GeometryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(geometryProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final showFullKeyboard = ref.watch(calculatorConfigProvider).config.showFullKeyboard;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputCard(context, ref, controller),
                const SizedBox(height: 24),
                if (controller.error != null)
                  Text(
                    controller.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.error,
                        ),
                  )
                else
                  _buildResultsCard(context, ref, controller),
                const SizedBox(height: 16),
                _buildFormulaCard(context, controller),
              ],
            ),
          ),
        ),
        NumericKeypad(
          showFullKeyboard: showFullKeyboard,
          showRec: true,
          onKeyPressed: (value) => _handleKeyPress(ref, value),
        ),
      ],
    );
  }

  void _handleKeyPress(WidgetRef ref, String value) {
    final controller = ref.read(geometryProvider);
    switch (value) {
      case 'clear':
        controller.clear();
      case 'backspace':
        controller.backspace();
      case 'rec':
        if (controller.results.isNotEmpty && controller.error == null) {
          controller.saveToHistory();
        }
      default:
        controller.append(value);
    }
  }

  Widget _buildShapeSelector(
    BuildContext context,
    WidgetRef ref,
    GeometryController controller,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: DropdownMenu<GeometryShape>(
        initialSelection: controller.shape,
        requestFocusOnTap: false,
        expandedInsets: EdgeInsets.zero,
        dropdownMenuEntries: GeometryShape.values.map((shape) {
          return DropdownMenuEntry(
            value: shape,
            label: shape.displayName,
          );
        }).toList(),
        onSelected: (value) {
          if (value != null) {
            ref.read(geometryProvider).setShape(value);
          }
        },
      ),
    );
  }

  Widget _buildInputCard(
    BuildContext context,
    WidgetRef ref,
    GeometryController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final fields = controller.inputFields;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '输入参数',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildShapeSelector(context, ref, controller),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: fields.map((field) {
                final value = controller.inputs[field] ?? '';
                final isActive = controller.activeField == field;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: TextEditingController(text: value)
                      ..selection = TextSelection.collapsed(
                        offset: value.length,
                      ),
                    readOnly: false,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: controller.service.getInputLabel(field),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.outline,
                        ),
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 64,
                        minHeight: 40,
                      ),
                      suffixIcon: _buildUnitDropdown(
                        context,
                        value: controller.inputUnit(field),
                        units: controller.inputUnits,
                        displayNames:
                            UnitCategory.length.unitDisplayNames,
                        onSelected: (unit) {
                          if (unit != null) {
                            ref
                                .read(geometryProvider)
                                .setInputUnit(field, unit);
                          }
                        },
                      ),
                    ),
                    onTap: () {
                      ref.read(geometryProvider).setActiveField(field);
                    },
                    onChanged: (text) {
                      ref.read(geometryProvider).setInput(field, text);
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _outputUnitDisplayNames(String resultName) {
    if (resultName.contains('体积')) {
      return UnitCategory.volume.unitDisplayNames;
    }
    if (resultName.contains('面积')) {
      return UnitCategory.area.unitDisplayNames;
    }
    return UnitCategory.length.unitDisplayNames;
  }

  Widget _buildUnitDropdown(
    BuildContext context, {
    required String value,
    required List<String> units,
    required Map<String, String> displayNames,
    required ValueChanged<String?> onSelected,
    TextStyle? selectedStyle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isDense: true,
        icon: const Icon(Icons.arrow_drop_down, size: 18),
        style: selectedStyle ??
            Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
        alignment: AlignmentDirectional.centerEnd,
        selectedItemBuilder: (context) {
          return units.map((unit) {
            return Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                unit,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList();
        },
        items: units.map((unit) {
          final displayName = displayNames[unit];
          return DropdownMenuItem(
            value: unit,
            child: Text(
              displayName != null ? '$unit（$displayName）' : unit,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }).toList(),
        onChanged: onSelected,
      ),
    );
  }

  Widget _buildResultsCard(
    BuildContext context,
    WidgetRef ref,
    GeometryController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final results = controller.results;

    if (results.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '计算结果',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Column(
              children: results.entries.map((entry) {
                final resultName = entry.key;
                final outputUnit = controller.outputUnit(resultName);
                final displayNames = _outputUnitDisplayNames(resultName);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    elevation: 0,
                    color: colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              resultName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: Text(
                              entry.value,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 80,
                              minWidth: 56,
                            ),
                            child: _buildUnitDropdown(
                              context,
                              value: outputUnit,
                              units: controller.outputUnits(resultName),
                              displayNames: displayNames,
                              selectedStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                              onSelected: (unit) {
                                if (unit != null) {
                                  ref
                                      .read(geometryProvider)
                                      .setOutputUnit(resultName, unit);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulaCard(BuildContext context, GeometryController controller) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: ExpansionTile(
        title: Text(
          '公式说明',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              controller.formulaDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
