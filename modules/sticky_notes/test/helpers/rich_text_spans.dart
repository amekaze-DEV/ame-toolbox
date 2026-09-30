import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 取承载 runs 的内层 [TextSpan]。
///
/// `Text.rich` 可能在外层再包一层样式 span（合并 `DefaultTextStyle`），
/// 因此断言行内 runs 前需要向下剥到真正承载子 span 的那一层。
TextSpan runsSpanOf(TextSpan span) {
  var current = span;
  while (current.children != null &&
      current.children!.length == 1 &&
      current.children!.first is TextSpan) {
    final only = current.children!.first as TextSpan;
    if (only.children == null || only.children!.isEmpty) break;
    current = only;
  }
  return current;
}

/// 取指定 widget 子树内、纯文本包含 [contains] 的首个 [RichText] 的 runs span。
///
/// [contains] 为 null 时取子树内首个 [RichText]。
TextSpan runsSpanIn(WidgetTester tester, Finder root, {String? contains}) {
  final finder = find.descendant(of: root, matching: find.byType(RichText));
  for (final widget in tester.widgetList<RichText>(finder)) {
    final span = widget.text as TextSpan;
    if (contains == null || span.toPlainText().contains(contains)) {
      return runsSpanOf(span);
    }
  }
  fail('未找到包含 "$contains" 的 RichText');
}