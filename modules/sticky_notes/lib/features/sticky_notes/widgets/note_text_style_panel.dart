import 'package:flutter/material.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

/// 可选字号范围（pt）。
const double kNoteFontSizeMin = 8;
const double kNoteFontSizeMax = 72;

/// 取色盘常用色（参考 Office 主题色板）。
///
/// 外层每项为一个基色的 6 档明暗梯度（[0] 为基色，其后依次为淡色 / 深色），
/// 渲染时按「行 = 明暗档位，列 = 基色」铺成 10 列 × 6 行色板。
const List<List<int>> noteTextColorPalette = <List<int>>[
  // 白
  <int>[0xFFFFFFFF, 0xFFF2F2F2, 0xFFD9D9D9, 0xFFBFBFBF, 0xFFA6A6A6, 0xFF7F7F7F],
  // 黑
  <int>[0xFF000000, 0xFF808080, 0xFF595959, 0xFF404040, 0xFF262626, 0xFF0D0D0D],
  // 浅灰
  <int>[0xFFE7E6E6, 0xFFD0CECE, 0xFFAFABAB, 0xFF767171, 0xFF3B3838, 0xFF181717],
  // 深蓝灰
  <int>[0xFF44546A, 0xFFD6DCE5, 0xFFADB9CA, 0xFF8497B0, 0xFF333F50, 0xFF222A35],
  // 蓝
  <int>[0xFF5B9BD5, 0xFFDEEBF7, 0xFFBDD7EE, 0xFF9DC3E6, 0xFF2E75B6, 0xFF1F4E79],
  // 橙
  <int>[0xFFED7D31, 0xFFFBE5D6, 0xFFF8CBAD, 0xFFF4B183, 0xFFC55A11, 0xFF843C0B],
  // 灰
  <int>[0xFFA5A5A5, 0xFFEDEDED, 0xFFDBDBDB, 0xFFC9C9C9, 0xFF7C7C7C, 0xFF535353],
  // 金
  <int>[0xFFFFC000, 0xFFFFF2CC, 0xFFFFE699, 0xFFFFD966, 0xFFBF9000, 0xFF7F6000],
  // 蓝（深）
  <int>[0xFF4472C4, 0xFFDAE3F3, 0xFFB4C7E7, 0xFF8FAADC, 0xFF2F5597, 0xFF203864],
  // 绿
  <int>[0xFF70AD47, 0xFFE2F0D9, 0xFFC5E0B4, 0xFFA9D18E, 0xFF548235, 0xFF385723],
];

/// 字号选择结果；[fontSize] 为 null 表示恢复默认（继承基础字号）。
class NoteFontSizeResult {
  const NoteFontSizeResult(this.fontSize);

  final double? fontSize;
}

/// 颜色选择结果；[colorValue] 为 null 表示恢复默认（继承主题色）。
class NoteColorResult {
  const NoteColorResult(this.colorValue);

  final int? colorValue;
}

/// 字号选择器（滑块 + 数值输入框）。
///
/// 返回 null 表示取消；返回 [NoteFontSizeResult.fontSize] 为 null 表示恢复默认。
Future<NoteFontSizeResult?> showNoteFontSizeDialog(
  BuildContext context, {
  required double baseFontSize,
  required double? current,
}) =>
    showDialog<NoteFontSizeResult>(
      context: context,
      builder: (_) => _FontSizeDialog(
        baseFontSize: baseFontSize,
        current: current,
      ),
    );

/// 字体颜色取色盘（常用色板 + 恢复默认）。
///
/// 返回 null 表示取消；返回 [NoteColorResult.colorValue] 为 null 表示恢复默认。
Future<NoteColorResult?> showNoteColorPaletteDialog(
  BuildContext context, {
  required int? current,
}) =>
    showDialog<NoteColorResult>(
      context: context,
      builder: (_) => _ColorPaletteDialog(current: current),
    );

/// 字号选择对话框。
class _FontSizeDialog extends StatefulWidget {
  const _FontSizeDialog({required this.baseFontSize, required this.current});

  final double baseFontSize;
  final double? current;

  @override
  State<_FontSizeDialog> createState() => _FontSizeDialogState();
}

class _FontSizeDialogState extends State<_FontSizeDialog> {
  late final TextEditingController _input;
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = _clamp(widget.current ?? widget.baseFontSize);
    _input = TextEditingController(text: _value.round().toString());
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  double _clamp(double value) =>
      value.clamp(kNoteFontSizeMin, kNoteFontSizeMax);

  void _setValue(double value, {bool syncInput = true}) {
    final next = _clamp(value);
    setState(() => _value = next);
    if (syncInput) _input.text = next.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('字号'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${_value.round()} pt', style: textTheme.bodyMedium),
                const Spacer(),
                SizedBox(
                  width: 96,
                  child: TextField(
                    controller: _input,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '数值',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (text) {
                      final parsed = double.tryParse(text.trim());
                      if (parsed == null) return;
                      _setValue(parsed, syncInput: false);
                    },
                  ),
                ),
              ],
            ),
            Slider(
              value: _value,
              min: kNoteFontSizeMin,
              max: kNoteFontSizeMax,
              divisions: (kNoteFontSizeMax - kNoteFontSizeMin).round(),
              label: '${_value.round()}',
              onChanged: _setValue,
            ),
          ],
        ),
      ),
      actions: [
        AdaptiveButton(
          variant: AdaptiveButtonVariant.text,
          label: '默认',
          onPressed: () => Navigator.of(context).pop(
            const NoteFontSizeResult(null),
          ),
        ),
        AdaptiveButton(
          variant: AdaptiveButtonVariant.text,
          label: '取消',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AdaptiveButton(
          variant: AdaptiveButtonVariant.filled,
          label: '应用',
          onPressed: () => Navigator.of(context).pop(
            NoteFontSizeResult(_value),
          ),
        ),
      ],
    );
  }
}

/// 字体颜色取色盘对话框。
class _ColorPaletteDialog extends StatelessWidget {
  const _ColorPaletteDialog({required this.current});

  final int? current;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('字体颜色'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('常用颜色', style: textTheme.labelLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var tone = 0; tone < _toneCount; tone++)
                  for (final column in noteTextColorPalette)
                    _buildSwatch(context, column[tone]),
              ],
            ),
          ],
        ),
      ),
      actions: [
        AdaptiveButton(
          variant: AdaptiveButtonVariant.text,
          label: '默认',
          onPressed: () => Navigator.of(context).pop(
            const NoteColorResult(null),
          ),
        ),
        AdaptiveButton(
          variant: AdaptiveButtonVariant.text,
          label: '取消',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  static int get _toneCount => noteTextColorPalette.first.length;

  Widget _buildSwatch(BuildContext context, int colorValue) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = Color(colorValue);
    final isSelected = current == colorValue;
    final onColor = color.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
    return Tooltip(
      message: _hexOf(colorValue),
      child: InkWell(
        onTap: () =>
            Navigator.of(context).pop(NoteColorResult(colorValue)),
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: isSelected
              ? Icon(Icons.check, size: 16, color: onColor)
              : null,
        ),
      ),
    );
  }

  String _hexOf(int colorValue) =>
      '#${(colorValue & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0')}';
}