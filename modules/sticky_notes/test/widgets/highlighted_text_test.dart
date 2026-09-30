import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/widgets/highlighted_text.dart';

import '../helpers/rich_text_spans.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// 取承载分段的内层 [TextSpan]。
///
/// `Text.rich` 会在外层再包一层样式 span，需向下剥到真正承载子 span 的那层。
TextSpan rootSpan(WidgetTester tester) =>
    runsSpanOf(tester.widget<RichText>(find.byType(RichText)).text as TextSpan);

void main() {
  testWidgets('命中字符高亮为独立段落，非命中段无高亮样式', (tester) async {
    await tester.pumpWidget(
      wrap(const HighlightedText(text: '工作汇报', indices: {2, 3})),
    );

    final children = rootSpan(tester).children!;
    expect(children.length, 2);
    expect((children[0] as TextSpan).text, '工作');
    expect((children[0] as TextSpan).style, isNull);
    expect((children[1] as TextSpan).text, '汇报');
    expect((children[1] as TextSpan).style?.backgroundColor, isNotNull);
  });

  testWidgets('不连续命中拆分为多段', (tester) async {
    await tester.pumpWidget(
      wrap(const HighlightedText(text: '工作汇报', indices: {0, 3})),
    );

    final children = rootSpan(tester).children!;
    expect(children.length, 3);
    expect((children[0] as TextSpan).text, '工');
    expect((children[0] as TextSpan).style?.backgroundColor, isNotNull);
    expect((children[1] as TextSpan).text, '作汇');
    expect((children[1] as TextSpan).style, isNull);
    expect((children[2] as TextSpan).text, '报');
    expect((children[2] as TextSpan).style?.backgroundColor, isNotNull);
  });

  testWidgets('无命中时渲染单段普通文本', (tester) async {
    await tester.pumpWidget(
      wrap(const HighlightedText(text: '工作汇报', indices: {})),
    );

    final children = rootSpan(tester).children!;
    expect(children.length, 1);
    expect((children[0] as TextSpan).text, '工作汇报');
    expect((children[0] as TextSpan).style, isNull);
  });

  testWidgets('越界下标被忽略且不抛异常', (tester) async {
    await tester.pumpWidget(
      wrap(const HighlightedText(text: '工作', indices: {-1, 9})),
    );

    final children = rootSpan(tester).children!;
    expect(children.length, 1);
    expect((children[0] as TextSpan).text, '工作');
  });

  testWidgets('自定义高亮样式生效', (tester) async {
    await tester.pumpWidget(
      wrap(
        const HighlightedText(
          text: '甲乙',
          indices: {0},
          highlightStyle: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );

    final children = rootSpan(tester).children!;
    expect((children[0] as TextSpan).style?.fontWeight, FontWeight.w900);
  });
}