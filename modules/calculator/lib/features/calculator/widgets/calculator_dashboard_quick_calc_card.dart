import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/calculator_page.dart';
import '../providers/calculator_config_provider.dart';
import '../providers/scientific_calculator_provider.dart';

/// 首页快速计算器卡片。
///
/// 提供一个极简表达式输入框，实时显示计算结果；
/// 当 [CalculatorConfig.showFullKeyboard] 开启时额外显示精简数字键盘。
/// 点击卡片空白处进入模块主页。
class CalculatorDashboardQuickCalcCard extends ConsumerStatefulWidget {
  const CalculatorDashboardQuickCalcCard({super.key});

  @override
  ConsumerState<CalculatorDashboardQuickCalcCard> createState() =>
      _CalculatorDashboardQuickCalcCardState();
}

class _CalculatorDashboardQuickCalcCardState
    extends ConsumerState<CalculatorDashboardQuickCalcCard> {
  final TextEditingController _controller = TextEditingController();
  String _result = '';

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      calculatorConfigProvider,
      (previous, next) {
        final prevConfig = previous?.config;
        final nextConfig = next.config;
        if (prevConfig?.scientificNotation != nextConfig.scientificNotation ||
            prevConfig?.decimalPrecision != nextConfig.decimalPrecision) {
          _onExpressionChanged(_controller.text);
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(calculatorConfigProvider).config;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openModule,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calculate_outlined,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '快速计算',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: '输入算式',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                onChanged: _onExpressionChanged,
              ),
              const SizedBox(height: 8),
              Text(
                _result.isEmpty ? ' ' : _result,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!config.showFullKeyboard) ...[
                const SizedBox(height: 12),
                _CompactOperatorBar(
                  onOperator: _append,
                  onClear: _clear,
                  onCalculate: _calculate,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onExpressionChanged(String expression) {
    final config = ref.read(calculatorConfigProvider).config;
    final service = ref.read(scientificCalculatorServiceProvider);
    final result = service.evaluate(
      expression,
      degrees: true,
      precision: config.decimalPrecision,
      scientificNotation: config.scientificNotation,
    );
    setState(() {
      _result = result.isError ? '' : result.display;
    });
  }

  void _append(String value) {
    final text = _controller.text;
    _controller.text = text + value;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _onExpressionChanged(_controller.text);
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _result = '';
    });
  }

  void _calculate() {
    _onExpressionChanged(_controller.text);
  }

  void _openModule() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CalculatorPage(),
      ),
    );
  }
}

class _CompactOperatorBar extends StatelessWidget {
  final ValueChanged<String> onOperator;
  final VoidCallback onClear;
  final VoidCallback onCalculate;

  const _CompactOperatorBar({
    required this.onOperator,
    required this.onClear,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    final operators = ['+', '-', '×', '÷', '(', ')'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final op in operators)
          ActionChip(
            label: Text(op),
            onPressed: () => onOperator(_mapOperator(op)),
          ),
        ActionChip(
          label: const Text('C'),
          onPressed: onClear,
        ),
        ActionChip(
          label: const Text('='),
          onPressed: onCalculate,
        ),
      ],
    );
  }

  String _mapOperator(String op) {
    return switch (op) {
      '×' => '*',
      '÷' => '/',
      _ => op,
    };
  }
}
