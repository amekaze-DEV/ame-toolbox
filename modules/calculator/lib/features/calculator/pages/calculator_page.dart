import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calculation.dart';
import '../services/calculator_service.dart';

final calculatorServiceProvider = Provider((_) => const CalculatorService());

final historyProvider = StateProvider<List<Calculation>>((_) => []);

final expressionProvider = StateProvider<String>((_) => '');

class CalculatorPage extends ConsumerWidget {
  const CalculatorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expression = ref.watch(expressionProvider);
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('多功能计算器'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: _DisplayPanel(
              expression: expression,
              history: history,
            ),
          ),
          Expanded(
            flex: 5,
            child: _Keypad(
              onInput: (value) => _handleInput(ref, value),
            ),
          ),
        ],
      ),
    );
  }

  void _handleInput(WidgetRef ref, String value) {
    final current = ref.read(expressionProvider);
    switch (value) {
      case 'C':
        ref.read(expressionProvider.notifier).state = '';
      case '⌫':
        if (current.isNotEmpty) {
          ref.read(expressionProvider.notifier).state =
              current.substring(0, current.length - 1);
        }
      case '=':
        _calculate(ref, current);
      default:
        ref.read(expressionProvider.notifier).state = current + value;
    }
  }

  void _calculate(WidgetRef ref, String expression) {
    if (expression.isEmpty) return;
    final service = ref.read(calculatorServiceProvider);
    try {
      final result = service.evaluate(expression);
      ref.read(expressionProvider.notifier).state = result.result;
      ref.read(historyProvider.notifier).update((state) => [result, ...state]);
    } on FormatException catch (e) {
      ref.read(expressionProvider.notifier).state = 'Error: ${e.message}';
    }
  }
}

class _DisplayPanel extends StatelessWidget {
  const _DisplayPanel({required this.expression, required this.history});

  final String expression;
  final List<Calculation> history;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Text(
                  '${item.expression} = ${item.result}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.end,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            expression.isEmpty ? '0' : expression,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onInput});

  final ValueChanged<String> onInput;

  @override
  Widget build(BuildContext context) {
    final buttons = const [
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '=', 'sqrt'],
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: buttons.map((row) {
          return Expanded(
            child: Row(
              children: row.map((label) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: _CalcButton(
                      label: label,
                      onPressed: () => onInput(label),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CalcButton extends StatelessWidget {
  const _CalcButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOperator = ['÷', '×', '-', '+', '='].contains(label);
    final isFunction = ['C', '⌫', '%', 'sqrt'].contains(label);

    Color? background;
    Color? foreground;
    if (isOperator) {
      background = colorScheme.primary;
      foreground = colorScheme.onPrimary;
    } else if (isFunction) {
      background = colorScheme.secondaryContainer;
      foreground = colorScheme.onSecondaryContainer;
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.zero,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
