import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../providers/radix_converter_controller.dart';
import '../providers/radix_converter_provider.dart';
import '../providers/calculator_config_provider.dart';
import '../services/radix_converter_service.dart';
import '../widgets/radix_input_formatter.dart';
import '../widgets/radix_keypad.dart';

/// 进制转换器页面。
///
/// 提供四个进制输入框实时同步。
class RadixConverterPage extends ConsumerWidget {
  const RadixConverterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(radixConverterProvider);
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
                _buildRadixInputs(context, ref, controller),
                if (controller.hint != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    controller.hint!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
        RadixKeypad(
          showFullKeyboard: showFullKeyboard,
          activeType: controller.activeType,
          onKeyPressed: (value) => _handleKeyPress(ref, value),
        ),
      ],
    );
  }

  void _handleKeyPress(WidgetRef ref, String value) {
    final controller = ref.read(radixConverterProvider);
    switch (value) {
      case 'clear':
        controller.clear();
      case 'backspace':
        controller.backspace();
      case '±':
        controller.toggleSign();
      default:
        controller.append(value);
    }
  }

  Widget _buildRadixInputs(
    BuildContext context,
    WidgetRef ref,
    RadixConverterController controller,
  ) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...RadixType.values.map((type) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRadixTextField(
                  context,
                  ref,
                  controller,
                  type: type,
                  value: controller.values[type] ?? '',
                ),
              );
            }),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AdaptiveButton(
                  variant: AdaptiveButtonVariant.text,
                  label: '记录',
                  onPressed: controller.values[controller.activeType]?.trim().isNotEmpty == true
                      ? () => ref.read(radixConverterProvider).saveToHistory()
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadixTextField(
    BuildContext context,
    WidgetRef ref,
    RadixConverterController controller, {
    required RadixType type,
    required String value,
  }) {
    return TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      decoration: InputDecoration(
        labelText: type.displayName,
        hintText: '请输入${type.displayName}数值',
        border: const OutlineInputBorder(),
      ),
      keyboardType: type == RadixType.hex
          ? TextInputType.text
          : const TextInputType.numberWithOptions(decimal: true, signed: true),
      textCapitalization: type == RadixType.hex
          ? TextCapitalization.characters
          : TextCapitalization.none,
      inputFormatters: [RadixInputFormatter(type)],
      onTap: () => controller.setActiveType(type),
      onChanged: (newValue) {
        ref.read(radixConverterProvider).setValue(type, newValue);
      },
    );
  }
}
