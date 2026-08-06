import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';
import 'package:ametoolbox/shared/widgets/adaptive_list_tile.dart';

import '../models/gas_type.dart';
import '../providers/standard_cubic_mass_controller.dart';
import '../providers/standard_cubic_mass_provider.dart';
import '../widgets/numeric_keypad.dart';

/// 标准立方米-质量转换页面。
///
/// 选择气体类型、摩尔质量，通过方向切换实现标准体积与质量的双向换算。
class StandardCubicMassPage extends ConsumerWidget {
  const StandardCubicMassPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(standardCubicMassProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGasSelector(context, ref, controller),
                const SizedBox(height: 16),
                _buildDensityCard(context, controller),
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
          showRec: true,
          onKeyPressed: (value) => _handleKeyPress(ref, value),
        ),
      ],
    );
  }

  void _handleKeyPress(WidgetRef ref, String value) {
    final controller = ref.read(standardCubicMassProvider);
    switch (value) {
      case 'clear':
        controller.clear();
      case 'backspace':
        controller.backspace();
      case 'rec':
        if (_canSave(controller)) {
          controller.saveToHistory();
        }
      default:
        controller.append(value);
    }
  }

  Widget _buildGasSelector(
    BuildContext context,
    WidgetRef ref,
    StandardCubicMassController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownMenu<GasType>(
          initialSelection: controller.gasType,
          requestFocusOnTap: false,
          label: const Text('气体类型'),
          expandedInsets: const EdgeInsets.symmetric(horizontal: 0),
          dropdownMenuEntries: GasType.values.map((gas) {
            return DropdownMenuEntry(
              value: gas,
              label: gas.displayName,
            );
          }).toList(),
          onSelected: (value) {
            if (value != null) {
              ref.read(standardCubicMassProvider).setGasType(value);
            }
          },
        ),
        const SizedBox(height: 12),
        _buildMolarMassField(context, ref, controller),
      ],
    );
  }

  Widget _buildMolarMassField(
    BuildContext context,
    WidgetRef ref,
    StandardCubicMassController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = controller.activeField == 'customMolarMass';
    final effectiveMolarMass = controller.isCustom
        ? controller.customMolarMass
        : controller.gasType.molarMass?.toString() ?? '';

    return TextField(
      controller: TextEditingController(text: effectiveMolarMass)
        ..selection = TextSelection.collapsed(
          offset: effectiveMolarMass.length,
        ),
      readOnly: false,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: '摩尔质量 M (g/mol)',
        helperText: controller.isCustom
            ? '自定义气体'
            : '可修改，修改后自动变为自定义气体',
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: isActive ? colorScheme.primary : colorScheme.outline,
          ),
        ),
      ),
      onTap: () {
        ref.read(standardCubicMassProvider).setActiveField('customMolarMass');
      },
      onChanged: (value) {
        ref.read(standardCubicMassProvider).setCustomMolarMass(value);
      },
    );
  }

  Widget _buildDensityCard(
    BuildContext context,
    StandardCubicMassController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: AdaptiveListTile(
        title: Text(
          '推导标准密度 ρ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        subtitle: Text(
          controller.density.isEmpty ? '—' : '${controller.density} kg/Nm³',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }

  Widget _buildConverterCard(
    BuildContext context,
    WidgetRef ref,
    StandardCubicMassController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isVolumeToMass =
        controller.direction == StandardCubicMassDirection.volumeToMass;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      // 上方始终为输入框
                      _buildQuantityRow(
                        context,
                        ref,
                        controller,
                        field: isVolumeToMass ? 'volume' : 'mass',
                        label: isVolumeToMass ? '标准体积' : '质量',
                        value: isVolumeToMass
                            ? controller.volumeValue
                            : controller.massValue,
                        unit: isVolumeToMass
                            ? controller.volumeUnit
                            : controller.massUnit,
                        units: isVolumeToMass
                            ? const ['Nm³']
                            : const ['kg', 'g', 't', 'lb', 'oz'],
                        readOnly: false,
                        unitReadOnly: isVolumeToMass,
                        onValueChanged: (value) {
                          if (isVolumeToMass) {
                            ref.read(standardCubicMassProvider).setVolumeValue(value);
                          } else {
                            ref.read(standardCubicMassProvider).setMassValue(value);
                          }
                        },
                        onUnitChanged: isVolumeToMass
                            ? null
                            : (unit) {
                                ref.read(standardCubicMassProvider).setMassUnit(unit!);
                              },
                      ),
                      const SizedBox(height: 16),
                      // 下方始终为输出框
                      _buildQuantityRow(
                        context,
                        ref,
                        controller,
                        field: isVolumeToMass ? 'mass' : 'volume',
                        label: isVolumeToMass ? '质量' : '标准体积',
                        value: isVolumeToMass
                            ? controller.massValue
                            : controller.volumeValue,
                        unit: isVolumeToMass
                            ? controller.massUnit
                            : controller.volumeUnit,
                        units: isVolumeToMass
                            ? const ['kg', 'g', 't', 'lb', 'oz']
                            : const ['Nm³'],
                        readOnly: true,
                        unitReadOnly: !isVolumeToMass,
                        onValueChanged: (_) {},
                        onUnitChanged: isVolumeToMass
                            ? (unit) {
                                ref.read(standardCubicMassProvider).setMassUnit(unit!);
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AdaptiveIconButton(
                  icon: const Icon(Icons.swap_vert),
                  tooltip: '切换方向',
                  onPressed: () => ref.read(standardCubicMassProvider).swapDirection(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFormulaText(context),
          ],
        ),
      ),
    );
  }

  bool _canSave(StandardCubicMassController controller) {
    final inputValue = controller.direction == StandardCubicMassDirection.volumeToMass
        ? controller.volumeValue
        : controller.massValue;
    final resultValue = controller.direction == StandardCubicMassDirection.volumeToMass
        ? controller.massValue
        : controller.volumeValue;
    return inputValue.trim().isNotEmpty &&
        resultValue.isNotEmpty &&
        resultValue != 'Error';
  }

  Widget _buildFormulaText(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      '公式：m = M × V / 22.414    Vm = 22.414 L/mol',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
    );
  }

  Widget _buildQuantityRow(
    BuildContext context,
    WidgetRef ref,
    StandardCubicMassController controller, {
    required String field,
    required String label,
    required String value,
    required String unit,
    required List<String> units,
    required ValueChanged<String> onValueChanged,
    ValueChanged<String?>? onUnitChanged,
    bool readOnly = false,
    bool unitReadOnly = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = controller.activeField == field;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 360;

        final valueField = TextField(
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
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isActive ? colorScheme.primary : colorScheme.outline,
              ),
            ),
          ),
          onTap: readOnly
              ? null
              : () {
                  ref.read(standardCubicMassProvider).setActiveField(field);
                },
          onChanged: readOnly ? null : onValueChanged,
        );

        final unitField = unitReadOnly
            ? TextField(
                controller: TextEditingController(text: unit)
                  ..selection = TextSelection.collapsed(offset: unit.length),
                readOnly: true,
                keyboardType: TextInputType.none,
                decoration: const InputDecoration(
                  labelText: '单位',
                  border: OutlineInputBorder(),
                ),
              )
            : DropdownMenu<String>(
                initialSelection: unit,
                requestFocusOnTap: false,
                label: const Text('单位'),
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: units.map((u) {
                  return DropdownMenuEntry(value: u, label: u);
                }).toList(),
                onSelected: onUnitChanged,
              );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              valueField,
              const SizedBox(height: 8),
              unitField,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: valueField),
            const SizedBox(width: 12),
            Expanded(flex: 1, child: unitField),
          ],
        );
      },
    );
  }
}
