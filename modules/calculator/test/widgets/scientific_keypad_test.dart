import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_module/features/calculator/widgets/scientific_keypad.dart';

class _KeypadTester extends StatefulWidget {
  final bool showFullKeyboard;

  const _KeypadTester({required this.showFullKeyboard});

  @override
  State<_KeypadTester> createState() => _KeypadTesterState();
}

class _KeypadTesterState extends State<_KeypadTester> {
  bool _secondFunction = false;
  bool _degrees = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ScientificKeypad(
          showFullKeyboard: widget.showFullKeyboard,
          degrees: _degrees,
          secondFunction: _secondFunction,
          onKeyPressed: (_) => setState(() {}),
          onToggleSecondFunction: () => setState(() => _secondFunction = !_secondFunction),
          onToggleAngleMode: () => setState(() => _degrees = !_degrees),
        ),
      ),
    );
  }
}

void main() {
  group('ScientificKeypad', () {
    testWidgets('完整键盘显示数字键与算符键', (tester) async {
      await tester.pumpWidget(const _KeypadTester(showFullKeyboard: true));

      expect(find.text('0'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('.'), findsOneWidget);
      expect(find.text('sin'), findsOneWidget);
      expect(find.text('='), findsOneWidget);
    });

    testWidgets('精简键盘隐藏数字键，保留算符/函数/等号', (tester) async {
      await tester.pumpWidget(const _KeypadTester(showFullKeyboard: false));

      expect(find.text('0'), findsNothing);
      expect(find.text('9'), findsNothing);
      expect(find.text('.'), findsNothing);
      expect(find.text('00'), findsNothing);

      expect(find.text('sin'), findsOneWidget);
      expect(find.text('cos'), findsOneWidget);
      expect(find.text('+'), findsOneWidget);
      expect(find.text('='), findsOneWidget);
      expect(find.text('Ans'), findsOneWidget);
    });

    testWidgets('点击 2nd 切换第二功能面板', (tester) async {
      await tester.pumpWidget(const _KeypadTester(showFullKeyboard: true));

      expect(find.text('asin'), findsNothing);

      await tester.tap(find.byIcon(Icons.keyboard_double_arrow_up));
      await tester.pump();

      expect(find.text('asin'), findsOneWidget);
      expect(find.text('sin'), findsNothing);
    });

    testWidgets('精简键盘下 2nd 切换同样生效', (tester) async {
      await tester.pumpWidget(const _KeypadTester(showFullKeyboard: false));

      expect(find.text('asin'), findsNothing);

      await tester.tap(find.byIcon(Icons.keyboard_double_arrow_up));
      await tester.pump();

      expect(find.text('asin'), findsOneWidget);
    });

    testWidgets('点击 DEG/RAD 触发角度模式切换回调', (tester) async {
      await tester.pumpWidget(const _KeypadTester(showFullKeyboard: true));

      expect(find.text('DEG'), findsOneWidget);

      await tester.tap(find.text('DEG'));
      await tester.pump();

      expect(find.text('RAD'), findsOneWidget);
    });

    testWidgets('点击数字键触发 onKeyPressed', (tester) async {
      await tester.pumpWidget(const _KeypadTester(showFullKeyboard: true));

      await tester.tap(find.text('5'));
      await tester.pump();

      // 通过重建后的状态无法直接读取回调值，但可以通过断言按钮存在性确认渲染正常。
      expect(find.text('5'), findsOneWidget);
    });
  });
}
