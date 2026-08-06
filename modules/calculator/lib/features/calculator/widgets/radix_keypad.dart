import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/radix_converter_service.dart';

/// 进制转换器专用键盘按键数据。
class _KeyCell {
  final String label;
  final String? value;
  final IconData? icon;
  final bool enabled;

  const _KeyCell({
    required this.label,
    this.value,
    this.icon,
    this.enabled = true,
  });
}

/// 进制转换器专用数字键盘。
///
/// 提供 0-9、A-F、退格、清空、小数点以及正负号切换。
/// 按键会根据当前 [activeType] 自动启用/禁用，例如二进制时只启用 0 与 1。
class RadixKeypad extends StatelessWidget {
  final RadixType activeType;
  final void Function(String value) onKeyPressed;

  const RadixKeypad({
    super.key,
    required this.activeType,
    required this.onKeyPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        const columnCount = 4;
        const rowCount = 5;
        const containerPadding = 8.0;
        const rowSpacing = 6.0;
        const cellSpacing = 6.0;
        const keyAspectRatio = 2.2;

        final horizontalSpacing = containerPadding * 2 + columnCount * cellSpacing;
        final verticalSpacing = containerPadding * 2 + rowCount * rowSpacing;

        final screenHeight = MediaQuery.sizeOf(context).height;
        final maxAllowedHeight = screenHeight * 0.38;
        final widthFromHeight = horizontalSpacing +
            columnCount *
                (maxAllowedHeight - verticalSpacing) /
                rowCount *
                keyAspectRatio;
        final keyboardWidth = math.min(constraints.maxWidth, widthFromHeight);
        final keyboardHeight = verticalSpacing +
            rowCount * (keyboardWidth - horizontalSpacing) / columnCount / keyAspectRatio;

        final rows = _buildRows();

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
                            padding: const EdgeInsets.symmetric(
                              horizontal: cellSpacing / 2,
                            ),
                            child: _KeyButton(
                              label: cell.label,
                              icon: cell.icon,
                              enabled: cell.enabled,
                              onPressed: cell.enabled
                                  ? () => _handleKey(cell)
                                  : null,
                              backgroundColor: _backgroundColor(
                                context,
                                cell,
                              ),
                              foregroundColor: _foregroundColor(
                                context,
                                cell,
                              ),
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

  List<List<_KeyCell>> _buildRows() {
    return [
      [
        _KeyCell(label: '7', value: '7', enabled: _isCharEnabled('7')),
        _KeyCell(label: '8', value: '8', enabled: _isCharEnabled('8')),
        _KeyCell(label: '9', value: '9', enabled: _isCharEnabled('9')),
        const _KeyCell(
          label: '⌫',
          value: 'backspace',
          icon: Icons.backspace_outlined,
        ),
      ],
      [
        _KeyCell(label: '4', value: '4', enabled: _isCharEnabled('4')),
        _KeyCell(label: '5', value: '5', enabled: _isCharEnabled('5')),
        _KeyCell(label: '6', value: '6', enabled: _isCharEnabled('6')),
        _KeyCell(label: 'A', value: 'A', enabled: _isCharEnabled('A')),
      ],
      [
        _KeyCell(label: '1', value: '1', enabled: _isCharEnabled('1')),
        _KeyCell(label: '2', value: '2', enabled: _isCharEnabled('2')),
        _KeyCell(label: '3', value: '3', enabled: _isCharEnabled('3')),
        _KeyCell(label: 'B', value: 'B', enabled: _isCharEnabled('B')),
      ],
      [
        _KeyCell(label: '0', value: '0', enabled: _isCharEnabled('0')),
        _KeyCell(
          label: '.',
          value: '.',
          enabled: activeType == RadixType.decimal,
        ),
        _KeyCell(label: 'C', value: 'C', enabled: _isCharEnabled('C')),
        _KeyCell(label: 'D', value: 'D', enabled: _isCharEnabled('D')),
      ],
      [
        _KeyCell(label: 'E', value: 'E', enabled: _isCharEnabled('E')),
        _KeyCell(label: 'F', value: 'F', enabled: _isCharEnabled('F')),
        _KeyCell(
          label: '±',
          value: '±',
          enabled: activeType == RadixType.decimal,
        ),
        const _KeyCell(
          label: 'C',
          value: 'clear',
          icon: Icons.clear,
        ),
      ],
    ];
  }

  bool _isCharEnabled(String char) {
    final validChars = activeType.validChars;
    return validChars.contains(char) || validChars.contains(char.toLowerCase());
  }

  void _handleKey(_KeyCell cell) {
    final value = cell.value;
    if (value != null && value.isNotEmpty) {
      onKeyPressed(value);
    }
  }

  Color? _backgroundColor(BuildContext context, _KeyCell cell) {
    final colorScheme = Theme.of(context).colorScheme;
    if (!cell.enabled) {
      return colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    }
    if (cell.value == 'clear') return colorScheme.errorContainer;
    if (cell.value == 'backspace') return colorScheme.surfaceContainerHighest;
    if (cell.value == '±') return colorScheme.secondaryContainer;
    return colorScheme.surface;
  }

  Color? _foregroundColor(BuildContext context, _KeyCell cell) {
    final colorScheme = Theme.of(context).colorScheme;
    if (cell.value == 'clear') return colorScheme.onErrorContainer;
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
    required this.onPressed,
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
      aspectRatio: 2.2,
      child: Material(
        color: effectiveBackground ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(child: child),
        ),
      ),
    );
  }
}
