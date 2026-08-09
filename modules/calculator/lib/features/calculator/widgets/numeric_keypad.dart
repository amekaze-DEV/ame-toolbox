import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 通用数字小键盘按键数据。
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

/// 通用数字小键盘。
///
/// 用于单位转换、几何计算、标准立方米-质量等需要数字输入的模块。
/// 支持可选的符号切换按钮（±）。
/// 当 [showFullKeyboard] 为 false 时仅显示控制键（紧凑模式）。
class NumericKeypad extends StatelessWidget {
  final void Function(String value) onKeyPressed;
  final bool showSignToggle;

  /// 是否在右下角显示 REC（记录）键。
  ///
  /// 开启后，点击 REC 会触发 [onKeyPressed] 并传入 `'rec'`，
  /// 由调用方处理保存历史记录逻辑。
  final bool showRec;

  /// 是否显示完整键盘。false 时仅显示控制键（C、⌫、±、REC）。
  final bool showFullKeyboard;

  const NumericKeypad({
    super.key,
    required this.onKeyPressed,
    this.showSignToggle = false,
    this.showRec = false,
    this.showFullKeyboard = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        const columnCount = 4;
        final rowCount = showFullKeyboard ? 4 : 1;
        const containerPadding = 8.0;
        const rowSpacing = 6.0;
        const cellSpacing = 6.0;
        const keyAspectRatio = 2.2;

        final horizontalSpacing = containerPadding * 2 + columnCount * cellSpacing;
        final verticalSpacing = containerPadding * 2 + rowCount * rowSpacing;

        final screenHeight = MediaQuery.sizeOf(context).height;
        final maxAllowedHeight = showFullKeyboard ? screenHeight * 0.4 : screenHeight * 0.1;
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
                                cell.label,
                              ),
                              foregroundColor: _foregroundColor(
                                context,
                                cell.label,
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
    if (!showFullKeyboard) {
      return [
        [
          const _KeyCell(label: 'C', value: 'clear'),
          const _KeyCell(label: '⌫', value: 'backspace', icon: Icons.backspace_outlined),
          _KeyCell(
            label: '±',
            value: '±',
            enabled: showSignToggle,
          ),
          const _KeyCell(label: 'REC', value: 'rec'),
        ],
      ];
    }
    return [
      [
        const _KeyCell(label: '7', value: '7'),
        const _KeyCell(label: '8', value: '8'),
        const _KeyCell(label: '9', value: '9'),
        const _KeyCell(label: '⌫', value: 'backspace', icon: Icons.backspace_outlined),
      ],
      [
        const _KeyCell(label: '4', value: '4'),
        const _KeyCell(label: '5', value: '5'),
        const _KeyCell(label: '6', value: '6'),
        const _KeyCell(label: 'C', value: 'clear'),
      ],
      [
        const _KeyCell(label: '1', value: '1'),
        const _KeyCell(label: '2', value: '2'),
        const _KeyCell(label: '3', value: '3'),
        _KeyCell(
          label: '±',
          value: '±',
          enabled: showSignToggle,
        ),
      ],
      [
        const _KeyCell(label: '00', value: '00'),
        const _KeyCell(label: '0', value: '0'),
        const _KeyCell(label: '.', value: '.'),
        if (showRec)
          const _KeyCell(label: 'REC', value: 'rec')
        else
          const _KeyCell(label: '', value: '', enabled: false),
      ],
    ];
  }

  void _handleKey(_KeyCell cell) {
    final value = cell.value;
    if (value != null && value.isNotEmpty) {
      onKeyPressed(value);
    }
  }

  Color? _backgroundColor(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    if (label == 'C') return colorScheme.errorContainer;
    if (label == 'REC') return colorScheme.primaryContainer;
    if (label == '⌫') return colorScheme.surfaceContainerHighest;
    if (label == '±') {
      return showSignToggle
          ? colorScheme.secondaryContainer
          : colorScheme.surface;
    }
    return colorScheme.surface;
  }

  Color? _foregroundColor(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
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
