import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 科学计算器键盘按键数据。
class _KeyCell {
  final String label;
  final String? value;
  final IconData? icon;

  const _KeyCell({
    required this.label,
    this.value,
    this.icon,
  });
}

/// 科学计算器 6 列竖版键盘。
///
/// 布局约定：
/// - 列 1–2：常用算符 / 函数 / 控制键
/// - 列 3–5：数字键盘（下部）与数字键盘上方的基础/括号键
/// - 列 6：基础算符（+、-、×、÷、=）
/// - 第 1 行右侧：C / ⌫
class ScientificKeypad extends StatelessWidget {
  final bool showFullKeyboard;
  final bool degrees;
  final bool secondFunction;
  final void Function(String value) onKeyPressed;
  final VoidCallback onToggleSecondFunction;
  final VoidCallback onToggleAngleMode;

  const ScientificKeypad({
    super.key,
    required this.showFullKeyboard,
    required this.degrees,
    required this.secondFunction,
    required this.onKeyPressed,
    required this.onToggleSecondFunction,
    required this.onToggleAngleMode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rows = showFullKeyboard
        ? (secondFunction ? _secondRows() : _firstRows())
        : (secondFunction ? _secondCompactRows() : _firstCompactRows());

    return LayoutBuilder(
      builder: (context, constraints) {
        const keyAspectRatio = 2.0;
        final columnCount = showFullKeyboard ? 6 : 4;
        const rowCount = 6;
        const containerPadding = 6.0;
        const rowSpacing = 4.0;
        const cellSpacing = 4.0;

        final horizontalSpacing = containerPadding * 2 + columnCount * cellSpacing;
        final verticalSpacing = containerPadding * 2 + rowCount * rowSpacing;

        final screenHeight = MediaQuery.sizeOf(context).height;
        final maxAllowedHeight = screenHeight / 2;
        final widthFromHeight = horizontalSpacing +
            columnCount *
                (maxAllowedHeight - verticalSpacing) /
                rowCount *
                keyAspectRatio;
        final keyboardWidth = math.min(constraints.maxWidth, widthFromHeight);
        final keyboardHeight = verticalSpacing +
            rowCount * (keyboardWidth - horizontalSpacing) / columnCount / keyAspectRatio;

        return Center(
          child: SizedBox(
            width: keyboardWidth,
            height: keyboardHeight,
            child: Container(
              color: colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(containerPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: rows.map((row) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: rowSpacing),
                    child: Row(
                      children: row.map((cell) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: cellSpacing / 2),
                            child: _KeyButton(
                              label: cell.label,
                              icon: cell.icon,
                              enabled: cell.value != null || cell.label == '2nd' || cell.label == 'DEG' || cell.label == 'RAD',
                              onPressed: () => _handleKey(cell),
                              backgroundColor: _backgroundColor(context, cell.label),
                              foregroundColor: _foregroundColor(context, cell.label),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  List<List<_KeyCell>> _firstRows() {
    return [
      [
        _KeyCell(label: '2nd', icon: Icons.keyboard_double_arrow_up),
        const _KeyCell(label: 'sin', value: 'sin('),
        const _KeyCell(label: 'cos', value: 'cos('),
        const _KeyCell(label: 'tan', value: 'tan('),
        const _KeyCell(label: 'C', value: 'C'),
        const _KeyCell(label: '⌫', value: 'backspace'),
      ],
      [
        _KeyCell(label: degrees ? 'DEG' : 'RAD'),
        const _KeyCell(label: 'π', value: 'pi'),
        const _KeyCell(label: '(', value: '('),
        const _KeyCell(label: ')', value: ')'),
        const _KeyCell(label: 'Ans', value: 'Ans'),
        const _KeyCell(label: '+', value: '+'),
      ],
      const [
        _KeyCell(label: 'log', value: 'log('),
        _KeyCell(label: 'e', value: 'e'),
        _KeyCell(label: '7', value: '7'),
        _KeyCell(label: '8', value: '8'),
        _KeyCell(label: '9', value: '9'),
        _KeyCell(label: '-', value: '-'),
      ],
      const [
        _KeyCell(label: 'ln', value: 'ln('),
        _KeyCell(label: '√', value: 'sqrt('),
        _KeyCell(label: '4', value: '4'),
        _KeyCell(label: '5', value: '5'),
        _KeyCell(label: '6', value: '6'),
        _KeyCell(label: '×', value: '×'),
      ],
      const [
        _KeyCell(label: '^', value: '^'),
        _KeyCell(label: 'x²', value: '^2'),
        _KeyCell(label: '1', value: '1'),
        _KeyCell(label: '2', value: '2'),
        _KeyCell(label: '3', value: '3'),
        _KeyCell(label: '÷', value: '÷'),
      ],
      const [
        _KeyCell(label: '±', value: '*-1'),
        _KeyCell(label: '%', value: '%'),
        _KeyCell(label: '00', value: '00'),
        _KeyCell(label: '0', value: '0'),
        _KeyCell(label: '.', value: '.'),
        _KeyCell(label: '=', value: '='),
      ],
    ];
  }

  List<List<_KeyCell>> _secondRows() {
    return [
      [
        _KeyCell(label: '2nd', icon: Icons.keyboard_double_arrow_up),
        const _KeyCell(label: 'asin', value: 'asin('),
        const _KeyCell(label: 'acos', value: 'acos('),
        const _KeyCell(label: 'atan', value: 'atan('),
        const _KeyCell(label: 'C', value: 'C'),
        const _KeyCell(label: '⌫', value: 'backspace'),
      ],
      [
        _KeyCell(label: degrees ? 'DEG' : 'RAD'),
        const _KeyCell(label: 'π', value: 'pi'),
        const _KeyCell(label: '(', value: '('),
        const _KeyCell(label: ')', value: ')'),
        const _KeyCell(label: 'Ans', value: 'Ans'),
        const _KeyCell(label: '+', value: '+'),
      ],
      const [
        _KeyCell(label: '10^x', value: '10^'),
        _KeyCell(label: 'e', value: 'e'),
        _KeyCell(label: '7', value: '7'),
        _KeyCell(label: '8', value: '8'),
        _KeyCell(label: '9', value: '9'),
        _KeyCell(label: '-', value: '-'),
      ],
      const [
        _KeyCell(label: 'e^x', value: 'e^'),
        _KeyCell(label: '³√', value: '^(1/3)'),
        _KeyCell(label: '4', value: '4'),
        _KeyCell(label: '5', value: '5'),
        _KeyCell(label: '6', value: '6'),
        _KeyCell(label: '×', value: '×'),
      ],
      const [
        _KeyCell(label: '1/x', value: '^(-1)'),
        _KeyCell(label: 'x³', value: '^3'),
        _KeyCell(label: '1', value: '1'),
        _KeyCell(label: '2', value: '2'),
        _KeyCell(label: '3', value: '3'),
        _KeyCell(label: '÷', value: '÷'),
      ],
      const [
        _KeyCell(label: 'abs', value: 'abs('),
        _KeyCell(label: 'fac', value: 'fac('),
        _KeyCell(label: '00', value: '00'),
        _KeyCell(label: '0', value: '0'),
        _KeyCell(label: '.', value: '.'),
        _KeyCell(label: '=', value: '='),
      ],
    ];
  }

  /// 精简键盘：隐藏数字键与小数点，保留算符、函数、常数、编辑与等号键。
  List<List<_KeyCell>> _firstCompactRows() {
    return [
      [
        _KeyCell(label: '2nd', icon: Icons.keyboard_double_arrow_up),
        const _KeyCell(label: 'sin', value: 'sin('),
        const _KeyCell(label: 'cos', value: 'cos('),
        const _KeyCell(label: 'tan', value: 'tan('),
      ],
      [
        _KeyCell(label: degrees ? 'DEG' : 'RAD'),
        const _KeyCell(label: 'π', value: 'pi'),
        const _KeyCell(label: '(', value: '('),
        const _KeyCell(label: ')', value: ')'),
      ],
      const [
        _KeyCell(label: 'Ans', value: 'Ans'),
        _KeyCell(label: '+', value: '+'),
        _KeyCell(label: '-', value: '-'),
        _KeyCell(label: '×', value: '×'),
      ],
      const [
        _KeyCell(label: '÷', value: '÷'),
        _KeyCell(label: '=', value: '='),
        _KeyCell(label: 'C', value: 'C'),
        _KeyCell(label: '⌫', value: 'backspace'),
      ],
      const [
        _KeyCell(label: 'log', value: 'log('),
        _KeyCell(label: 'ln', value: 'ln('),
        _KeyCell(label: 'e', value: 'e'),
        _KeyCell(label: '^', value: '^'),
      ],
      const [
        _KeyCell(label: '√', value: 'sqrt('),
        _KeyCell(label: 'x²', value: '^2'),
        _KeyCell(label: '±', value: '*-1'),
        _KeyCell(label: '%', value: '%'),
      ],
    ];
  }

  /// 精简键盘下的第二功能面板。
  List<List<_KeyCell>> _secondCompactRows() {
    return [
      [
        _KeyCell(label: '2nd', icon: Icons.keyboard_double_arrow_up),
        const _KeyCell(label: 'asin', value: 'asin('),
        const _KeyCell(label: 'acos', value: 'acos('),
        const _KeyCell(label: 'atan', value: 'atan('),
      ],
      [
        _KeyCell(label: degrees ? 'DEG' : 'RAD'),
        const _KeyCell(label: 'π', value: 'pi'),
        const _KeyCell(label: '(', value: '('),
        const _KeyCell(label: ')', value: ')'),
      ],
      const [
        _KeyCell(label: 'Ans', value: 'Ans'),
        _KeyCell(label: '+', value: '+'),
        _KeyCell(label: '-', value: '-'),
        _KeyCell(label: '×', value: '×'),
      ],
      const [
        _KeyCell(label: '÷', value: '÷'),
        _KeyCell(label: '=', value: '='),
        _KeyCell(label: 'C', value: 'C'),
        _KeyCell(label: '⌫', value: 'backspace'),
      ],
      const [
        _KeyCell(label: '10^x', value: '10^'),
        _KeyCell(label: 'e^x', value: 'e^'),
        _KeyCell(label: 'e', value: 'e'),
        _KeyCell(label: '1/x', value: '^(-1)'),
      ],
      const [
        _KeyCell(label: '³√', value: '^(1/3)'),
        _KeyCell(label: 'x³', value: '^3'),
        _KeyCell(label: 'abs', value: 'abs('),
        _KeyCell(label: 'fac', value: 'fac('),
      ],
    ];
  }

  void _handleKey(_KeyCell cell) {
    final label = cell.label;
    if (label == '2nd') {
      onToggleSecondFunction();
      return;
    }
    if (label == 'DEG' || label == 'RAD') {
      onToggleAngleMode();
      return;
    }
    final value = cell.value;
    if (value != null && value.isNotEmpty) {
      onKeyPressed(value);
    }
  }

  Color? _backgroundColor(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    if (label == '2nd' && secondFunction) {
      return colorScheme.primaryContainer;
    }
    if (label == 'DEG' || label == 'RAD') {
      return colorScheme.secondaryContainer;
    }
    if (label == 'C') return colorScheme.errorContainer;
    if (label == '=') return colorScheme.primary;
    if (['+', '-', '×', '÷'].contains(label)) {
      return colorScheme.secondaryContainer;
    }
    if (['sin', 'cos', 'tan', 'asin', 'acos', 'atan'].contains(label)) {
      return colorScheme.tertiaryContainer;
    }
    if ([
      'log',
      'ln',
      'π',
      'e',
      '^',
      '√',
      'x²',
      'x³',
      '³√',
      '1/x',
      'e^x',
      '10^x',
      'abs',
      'fac',
    ].contains(label)) {
      return colorScheme.surfaceContainerHighest;
    }
    return colorScheme.surface;
  }

  Color? _foregroundColor(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    if (label == '=') return colorScheme.onPrimary;
    if (label == 'C') return colorScheme.onErrorContainer;
    return null;
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool enabled;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const _KeyButton({
    required this.label,
    this.icon,
    this.enabled = true,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBackground = enabled
        ? backgroundColor
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

    final Widget child = icon != null
        ? Icon(icon, color: foregroundColor)
        : Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w500,
                ),
          );

    return AspectRatio(
      aspectRatio: 2.0,
      child: Material(
        color: effectiveBackground ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Center(child: child),
        ),
      ),
    );
  }
}
