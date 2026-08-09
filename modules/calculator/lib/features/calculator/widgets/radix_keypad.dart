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
/// 当 [showFullKeyboard] 为 false 时仅显示 A-F 字母键与控制键（紧凑模式）。
class RadixKeypad extends StatelessWidget {
  final RadixType activeType;
  final void Function(String value) onKeyPressed;

  /// 是否显示完整键盘。false 时仅显示 A-F 字母键与控制键。
  final bool showFullKeyboard;

  const RadixKeypad({
    super.key,
    required this.activeType,
    required this.onKeyPressed,
    this.showFullKeyboard = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        const columnCount = 5;
        final rowCount = showFullKeyboard ? 4 : 2;
        const containerPadding = 8.0;
        const rowSpacing = 6.0;
        const cellSpacing = 6.0;
        const keyAspectRatio = 2.2;

        final horizontalSpacing = containerPadding * 2 + columnCount * cellSpacing;
        final verticalSpacing = containerPadding * 2 + rowCount * rowSpacing;

        final screenHeight = MediaQuery.sizeOf(context).height;
        final maxAllowedHeight = showFullKeyboard ? screenHeight * 0.4 : screenHeight * 0.27;
        final minAllowedHeight = 0.0;
        final widthFromHeight = horizontalSpacing +
            columnCount *
                (maxAllowedHeight - verticalSpacing) /
                rowCount *
                keyAspectRatio;
        final keyboardWidth = math.min(constraints.maxWidth, widthFromHeight);
        final keyboardHeight = math.max(
          minAllowedHeight,
          verticalSpacing +
              rowCount * (keyboardWidth - horizontalSpacing) / columnCount / keyAspectRatio,
        );

        if (!showFullKeyboard) {
          return _buildCompactLayout(
            context: context,
            keyboardWidth: keyboardWidth,
            keyboardHeight: keyboardHeight,
            containerPadding: containerPadding,
            rowSpacing: rowSpacing,
            cellSpacing: cellSpacing,
            columnCount: columnCount,
            colorScheme: colorScheme,
          );
        }

        final rows = _buildRows();

        return Center(
          child: SizedBox(
            width: keyboardWidth,
            height: keyboardHeight,
            child: Container(
              color: colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(containerPadding),
              child: Column(
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

  /// 完整键盘：5列4行。
  List<List<_KeyCell>> _buildRows() {
    return [
      [
        _KeyCell(label: 'A', value: 'A', enabled: _isCharEnabled('A')),
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
        _KeyCell(label: 'B', value: 'B', enabled: _isCharEnabled('B')),
        _KeyCell(label: '4', value: '4', enabled: _isCharEnabled('4')),
        _KeyCell(label: '5', value: '5', enabled: _isCharEnabled('5')),
        _KeyCell(label: '6', value: '6', enabled: _isCharEnabled('6')),
        const _KeyCell(
          label: '清空',
          value: 'clear',
          icon: Icons.clear,
        ),
      ],
      [
        _KeyCell(label: 'C', value: 'C', enabled: _isCharEnabled('C')),
        _KeyCell(label: '1', value: '1', enabled: _isCharEnabled('1')),
        _KeyCell(label: '2', value: '2', enabled: _isCharEnabled('2')),
        _KeyCell(label: '3', value: '3', enabled: _isCharEnabled('3')),
        _KeyCell(
          label: '±',
          value: '±',
          enabled: activeType == RadixType.decimal,
        ),
      ],
      [
        _KeyCell(label: 'D', value: 'D', enabled: _isCharEnabled('D')),
        _KeyCell(label: 'E', value: 'E', enabled: _isCharEnabled('E')),
        _KeyCell(label: 'F', value: 'F', enabled: _isCharEnabled('F')),
        _KeyCell(label: '0', value: '0', enabled: _isCharEnabled('0')),
        _KeyCell(
          label: '.',
          value: '.',
          enabled: activeType == RadixType.decimal,
        ),
      ],
    ];
  }

  /// 紧凑键盘：5列2行，±键为双行高。
  /// 列1：±（双行高）；列2-5第一行：A|B|C|⌫；第二行：D|E|F|清空。
  Widget _buildCompactLayout({
    required BuildContext context,
    required double keyboardWidth,
    required double keyboardHeight,
    required double containerPadding,
    required double rowSpacing,
    required double cellSpacing,
    required int columnCount,
    required ColorScheme colorScheme,
  }) {
    final cellWidth = (keyboardWidth - containerPadding * 2 - columnCount * cellSpacing) / columnCount;
    final doubleHeight = keyboardHeight - containerPadding * 2;

    final compactRows = [
      [
        _KeyCell(label: 'A', value: 'A', enabled: _isCharEnabled('A')),
        _KeyCell(label: 'B', value: 'B', enabled: _isCharEnabled('B')),
        _KeyCell(label: 'C', value: 'C', enabled: _isCharEnabled('C')),
        const _KeyCell(
          label: '⌫',
          value: 'backspace',
          icon: Icons.backspace_outlined,
        ),
      ],
      [
        _KeyCell(label: 'D', value: 'D', enabled: _isCharEnabled('D')),
        _KeyCell(label: 'E', value: 'E', enabled: _isCharEnabled('E')),
        _KeyCell(label: 'F', value: 'F', enabled: _isCharEnabled('F')),
        const _KeyCell(
          label: '清空',
          value: 'clear',
          icon: Icons.clear,
        ),
      ],
    ];

    return Center(
      child: SizedBox(
        width: keyboardWidth,
        height: keyboardHeight,
        child: Container(
          color: colorScheme.surfaceContainerHighest,
          padding: EdgeInsets.all(containerPadding),
          child: Row(
            children: [
              // ± 键（双行高）
              Padding(
                padding: EdgeInsets.only(right: cellSpacing / 2),
                child: SizedBox(
                  width: cellWidth,
                  height: doubleHeight,
                  child: _DoubleHeightKeyButton(
                    label: '±',
                    enabled: activeType == RadixType.decimal,
                    onPressed: activeType == RadixType.decimal
                        ? () => onKeyPressed('±')
                        : null,
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: null,
                    height: doubleHeight,
                  ),
                ),
              ),
              // A-F 键与控制键
              Expanded(
                child: Column(
                  children: compactRows.asMap().entries.map((entry) {
                    final rowIndex = entry.key;
                    final row = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: rowIndex < compactRows.length - 1 ? rowSpacing : 0,
                      ),
                      child: Row(
                        children: row.map((cell) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: cellSpacing / 2,
                              ),
                              child: _KeyButton(
                                label: cell.label,
                                icon: cell.icon,
                                enabled: cell.enabled,
                                onPressed: cell.enabled
                                    ? () => _handleKey(cell)
                                    : null,
                                backgroundColor: _backgroundColor(context, cell),
                                foregroundColor: _foregroundColor(context, cell),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

/// 双行高按键，用于紧凑键盘中的 ± 键。
class _DoubleHeightKeyButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;

  const _DoubleHeightKeyButton({
    required this.label,
    this.enabled = true,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBackground = enabled
        ? backgroundColor
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

    final Widget child = Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w500,
          ),
    );

    return SizedBox(
      height: height,
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
