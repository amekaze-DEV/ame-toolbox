import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/unit_category.dart';
import '../providers/calculator_config_provider.dart';
import '../providers/unit_converter_controller.dart';
import '../providers/unit_converter_provider.dart';
import '../widgets/numeric_keypad.dart';

/// 单位转换器页面。
///
/// 顶部选择类别，下方双单位输入 + 交换按钮，实时换算。
class UnitConverterPage extends ConsumerWidget {
  const UnitConverterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(unitConverterProvider);
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
                _buildCategorySelector(context, ref, controller),
                const SizedBox(height: 24),
                _buildConverterCard(context, ref, controller),
                if (controller.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    controller.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.error,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
        NumericKeypad(
          showFullKeyboard: showFullKeyboard,
          showSignToggle: controller.category == UnitCategory.temperature,
          showRec: true,
          onKeyPressed: (value) => _handleKeyPress(ref, value),
        ),
      ],
    );
  }

  void _handleKeyPress(WidgetRef ref, String value) {
    final controller = ref.read(unitConverterProvider);
    switch (value) {
      case 'clear':
        controller.clear();
      case 'backspace':
        controller.backspace();
      case 'rec':
        if (controller.fromValue.trim().isNotEmpty &&
            controller.result.isNotEmpty &&
            controller.result != 'Error') {
          controller.saveToHistory();
        }
      default:
        controller.append(value);
    }
  }

  Widget _buildCategorySelector(
    BuildContext context,
    WidgetRef ref,
    UnitConverterController controller,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: DropdownMenu<UnitCategory>(
        width: 140,
        initialSelection: controller.category,
        requestFocusOnTap: false,
        label: const Text('类别'),
        expandedInsets: EdgeInsets.zero,
        dropdownMenuEntries: UnitCategory.values.map((category) {
          return DropdownMenuEntry(
            value: category,
            label: category.displayName,
          );
        }).toList(),
        onSelected: (value) {
          if (value != null) {
            ref.read(unitConverterProvider).setCategory(value);
          }
        },
      ),
    );
  }

  Widget _buildConverterCard(
    BuildContext context,
    WidgetRef ref,
    UnitConverterController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildUnitRow(
                        context,
                        ref,
                        controller,
                        label: '输入',
                        value: controller.fromValue,
                        unit: controller.fromUnit,
                        units: controller.units,
                        readOnly: false,
                        onValueChanged: (value) {
                          ref.read(unitConverterProvider).setFromValue(value);
                        },
                        onUnitChanged: (unit) {
                          ref.read(unitConverterProvider).setFromUnit(unit!);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildUnitRow(
                        context,
                        ref,
                        controller,
                        label: '结果',
                        value: controller.result.isEmpty
                            ? '-'
                            : controller.result,
                        unit: controller.toUnit,
                        units: controller.units,
                        readOnly: true,
                        onUnitChanged: (unit) {
                          ref.read(unitConverterProvider).setToUnit(unit!);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: AdaptiveIconButton(
                    icon: const Icon(Icons.swap_vert),
                    tooltip: '交换单位',
                    onPressed: () => ref.read(unitConverterProvider).swap(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitRow(
    BuildContext context,
    WidgetRef ref,
    UnitConverterController controller, {
    required String label,
    required String value,
    required String unit,
    required List<String> units,
    required ValueChanged<String?> onUnitChanged,
    ValueChanged<String>? onValueChanged,
    bool readOnly = false,
  }) {
    return TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      readOnly: readOnly,
      keyboardType: readOnly
          ? TextInputType.none
          : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: readOnly ? '' : '请输入数值',
        border: const OutlineInputBorder(),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 76,
          minHeight: 40,
        ),
        suffixIcon: _buildUnitDropdown(
          context,
          value: unit,
          units: units,
          displayNames: controller.category.unitDisplayNames,
          onSelected: onUnitChanged,
        ),
      ),
      onChanged: readOnly ? null : onValueChanged,
    );
  }

  Widget _buildUnitDropdown(
    BuildContext context, {
    required String value,
    required List<String> units,
    required Map<String, String> displayNames,
    required ValueChanged<String?> onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isDense: true,
        icon: const Icon(Icons.arrow_drop_down, size: 18),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
}
