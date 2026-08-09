import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../providers/exchange_rate_controller.dart';
import '../providers/exchange_rate_provider.dart';
import '../providers/calculator_config_provider.dart';
import '../services/exchange_rate_service.dart';
import '../widgets/numeric_keypad.dart';

/// 汇率计算器页面。
///
/// 提供货币选择、金额输入、手动刷新、离线缓存提示与实时换算结果展示。
/// 布局参照 [UnitConverterPage]，包含数字小键盘与卡片内操作按钮。
class ExchangeRatePage extends ConsumerWidget {
  const ExchangeRatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(exchangeRateProvider);
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
                _buildStatusBar(context, controller),
                const SizedBox(height: 24),
                _buildConverterCard(context, ref, controller),
                if (controller.status == ExchangeRateStatus.error &&
                    controller.message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    controller.message!,
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
          showRec: true,
          onKeyPressed: (value) => _handleKeyPress(ref, value),
        ),
      ],
    );
  }

  void _handleKeyPress(WidgetRef ref, String value) {
    final controller = ref.read(exchangeRateProvider);
    switch (value) {
      case 'clear':
        controller.clear();
      case 'backspace':
        controller.backspace();
      case 'rec':
        if (controller.amount.trim().isNotEmpty &&
            controller.result.isNotEmpty &&
            controller.result != 'Error') {
          controller.saveToHistory();
        }
      default:
        controller.append(value);
    }
  }

  Widget _buildStatusBar(BuildContext context, ExchangeRateController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final message = controller.message;

    if (controller.status == ExchangeRateStatus.loading) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            '正在刷新汇率...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }

    final isError = controller.status == ExchangeRateStatus.error;

    return Row(
      children: [
        Icon(
          isError ? Icons.error_outline : Icons.info_outline,
          size: 18,
          color: isError ? colorScheme.error : colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isError ? colorScheme.error : colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildConverterCard(
    BuildContext context,
    WidgetRef ref,
    ExchangeRateController controller,
  ) {
    final currencies = controller.currencies;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                      _buildCurrencyRow(
                        context,
                        ref,
                        controller,
                        label: '持有货币',
                        value: controller.amount,
                        currency: controller.fromCurrency,
                        currencies: currencies,
                        readOnly: false,
                        onValueChanged: (value) {
                          ref.read(exchangeRateProvider).setAmount(value);
                        },
                        onCurrencyChanged: (currency) {
                          if (currency != null) {
                            ref.read(exchangeRateProvider).setFromCurrency(currency);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildCurrencyRow(
                        context,
                        ref,
                        controller,
                        label: '目标货币',
                        value: controller.result.isEmpty ? '-' : controller.result,
                        currency: controller.toCurrency,
                        currencies: currencies,
                        readOnly: true,
                        onCurrencyChanged: (currency) {
                          if (currency != null) {
                            ref.read(exchangeRateProvider).setToCurrency(currency);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AdaptiveIconButton(
                  icon: const Icon(Icons.swap_vert),
                  tooltip: '交换货币',
                  onPressed: () => ref.read(exchangeRateProvider).swap(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                AdaptiveButton(
                  variant: AdaptiveButtonVariant.text,
                  icon: Icons.refresh,
                  label: '刷新汇率',
                  onPressed: controller.status == ExchangeRateStatus.loading
                      ? null
                      : () => ref.read(exchangeRateProvider).refresh(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyRow(
    BuildContext context,
    WidgetRef ref,
    ExchangeRateController controller, {
    required String label,
    required String value,
    required String currency,
    required List<String> currencies,
    required ValueChanged<String?> onCurrencyChanged,
    ValueChanged<String>? onValueChanged,
    bool readOnly = false,
  }) {
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
            hintText: readOnly ? '' : '请输入金额',
            border: const OutlineInputBorder(),
          ),
          onChanged: onValueChanged,
        );

        final currencyDropdown = DropdownMenu<String>(
          key: ValueKey('${label}_currency_$currency'),
          initialSelection: currency,
          requestFocusOnTap: true,
          enableFilter: true,
          label: const Text('货币'),
          expandedInsets: EdgeInsets.zero,
          dropdownMenuEntries: currencies.map((c) {
            final name = ExchangeRateService.getCurrencyDisplayName(c);
            return DropdownMenuEntry(
                value: c, label: name != c ? '$c（$name）' : c);
          }).toList(),
          onSelected: onCurrencyChanged,
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              valueField,
              const SizedBox(height: 8),
              currencyDropdown,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: valueField),
            const SizedBox(width: 12),
            Expanded(flex: 1, child: currencyDropdown),
          ],
        );
      },
    );
  }
}
