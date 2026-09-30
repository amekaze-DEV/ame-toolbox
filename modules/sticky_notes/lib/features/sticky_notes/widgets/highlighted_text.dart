import 'package:flutter/material.dart';

/// 带命中高亮的文本。
///
/// [indices] 为需高亮的字符下标（可乱序、可重复）；连续下标合并为一段，
/// 非命中段沿用 [style]，命中段叠加 [highlightStyle]（默认为
/// `colorScheme.primaryContainer` 背景 + 加粗）。
/// 索引越界会被忽略，保证与源文本不匹配时安全降级。
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.indices,
    this.style,
    this.highlightStyle,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  /// 源文本。
  final String text;

  /// 需高亮的字符下标（通常来自检索结果）。
  final Set<int> indices;

  /// 普通文本样式。
  final TextStyle? style;

  /// 命中文本样式；为 null 时使用主题默认高亮样式。
  final TextStyle? highlightStyle;

  final int? maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveHighlight = highlightStyle ??
        TextStyle(
          backgroundColor: theme.colorScheme.primaryContainer,
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        );

    return Text.rich(
      TextSpan(
        children: _segments(effectiveHighlight),
      ),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// 把命中下标合并为连续区间，切分为「命中 / 非命中」交替的文本段。
  List<InlineSpan> _segments(TextStyle effectiveHighlight) {
    final valid = indices.where((i) => i >= 0 && i < text.length).toSet();
    if (valid.isEmpty) return [TextSpan(text: text)];

    final spans = <InlineSpan>[];
    final buffer = StringBuffer();
    var highlighting = false;

    void flush() {
      if (buffer.isEmpty) return;
      spans.add(
        TextSpan(
          text: buffer.toString(),
          style: highlighting ? effectiveHighlight : null,
        ),
      );
      buffer.clear();
    }

    for (var i = 0; i < text.length; i++) {
      final hit = valid.contains(i);
      if (hit != highlighting) {
        flush();
        highlighting = hit;
      }
      buffer.write(text[i]);
    }
    flush();
    return spans;
  }
}