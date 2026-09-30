import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_block.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';
import 'package:sticky_notes_module/features/sticky_notes/widgets/note_rich_text_editor.dart';
import 'package:sticky_notes_module/features/sticky_notes/widgets/rich_text_editing_controller.dart';

Widget wrap(Widget child) => InputModeScope(
      mode: InputMode.touch,
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

/// 对话框内的数值输入框（与编辑器正文输入框区分）。
Finder dialogTextField() => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );

/// 取色盘中指定颜色的色块。
Finder swatchOf(int colorValue) => find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).color == Color(colorValue),
    );

void main() {
  /// 取编辑框实际渲染所用的 [TextSpan]（即 `EditableText` 调用控制器构建的结果）。
  TextSpan currentSpan(WidgetTester tester) {
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    final controller = editable.controller as RichTextEditingController;
    return controller.buildTextSpan(
      context: tester.element(find.byType(EditableText)),
      style: null,
      withComposing: false,
    );
  }

  /// 文本块基础样式。
  TextStyle baseStyle(WidgetTester tester) => currentSpan(tester).style!;

  /// 首个 run 的最终渲染样式。
  TextStyle runStyle(WidgetTester tester) {
    final span = currentSpan(tester);
    final children = span.children;
    if (children == null || children.isEmpty) return span.style!;
    return (children.first as TextSpan).style!;
  }

  ThemeData themeOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(EditableText)));

  /// 取正文控制器。
  RichTextEditingController bodyController(WidgetTester tester) {
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    return editable.controller as RichTextEditingController;
  }

  /// 全选正文（模拟「先选中文本再调整格式」）。
  Future<void> selectAllBody(WidgetTester tester) async {
    final controller = bodyController(tester);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    await tester.pump();
  }

  Future<void> pumpEditor(WidgetTester tester,
      {List<NoteBlock>? blocks}) async {
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: blocks ??
              const [ParagraphBlock(inlines: [NoteInline(text: '文本')])],
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('选中文本后点击加粗，实际渲染为粗体', (tester) async {
    await pumpEditor(tester);
    expect(runStyle(tester).fontWeight, isNot(FontWeight.bold));

    await selectAllBody(tester);
    await tester.tap(find.byTooltip('加粗'));
    await tester.pumpAndSettle();

    expect(runStyle(tester).fontWeight, FontWeight.bold);
  });

  testWidgets('选中文本后点击下划线，实际渲染下划线', (tester) async {
    await pumpEditor(tester);
    expect(runStyle(tester).decoration, TextDecoration.none);

    await selectAllBody(tester);
    await tester.tap(find.byTooltip('下划线'));
    await tester.pumpAndSettle();

    expect(runStyle(tester).decoration, TextDecoration.underline);
  });

  testWidgets('折叠光标改样式不改已输入文本，仅后续输入生效', (tester) async {
    await pumpEditor(tester);
    expect(runStyle(tester).fontWeight, isNot(FontWeight.bold));

    // 折叠光标（未选中任何文本）下点加粗：已输入文本保持不变。
    await tester.tap(find.byTooltip('加粗'));
    await tester.pumpAndSettle();
    expect(runStyle(tester).fontWeight, isNot(FontWeight.bold));

    // 随后输入的文本继承该样式。
    await tester.enterText(find.byType(EditableText), '新增');
    await tester.pumpAndSettle();
    expect(runStyle(tester).fontWeight, FontWeight.bold);
  });

  testWidgets('选中文本后点击斜体与删除线实际渲染生效且互不覆盖', (tester) async {
    await pumpEditor(tester);

    await selectAllBody(tester);
    await tester.tap(find.byTooltip('斜体'));
    await tester.pumpAndSettle();
    expect(runStyle(tester).fontStyle, FontStyle.italic);

    await tester.tap(find.byTooltip('删除线'));
    await tester.pumpAndSettle();
    expect(runStyle(tester).decoration, TextDecoration.lineThrough);
    expect(runStyle(tester).fontStyle, FontStyle.italic);
  });

  testWidgets('字号对话框设定后实际渲染绝对字号', (tester) async {
    await pumpEditor(tester);
    final base = baseStyle(tester);

    await selectAllBody(tester);
    await tester.tap(find.byTooltip('字号'));
    await tester.pumpAndSettle();
    await tester.enterText(dialogTextField(), '26');
    await tester.pumpAndSettle();
    await tester.tap(find.text('应用'));
    await tester.pumpAndSettle();

    expect(runStyle(tester).fontSize, 26);
    expect(base.fontSize, isNotNull);
  });

  testWidgets('取色盘选色后实际渲染自定义颜色', (tester) async {
    await pumpEditor(tester);

    await selectAllBody(tester);
    await tester.tap(find.byTooltip('字体颜色'));
    await tester.pumpAndSettle();
    await tester.tap(swatchOf(0xFFED7D31));
    await tester.pumpAndSettle();

    expect(runStyle(tester).color, const Color(0xFFED7D31));
  });

  testWidgets('恢复默认后回到主题基础样式', (tester) async {
    await pumpEditor(tester, blocks: const [
      ParagraphBlock(
        inlines: [NoteInline(text: '文本', fontSize: 30, colorValue: 0xFFED7D31)],
      ),
    ]);
    final theme = themeOf(tester);
    expect(runStyle(tester).fontSize, 30);
    expect(runStyle(tester).color, const Color(0xFFED7D31));

    await selectAllBody(tester);
    await tester.tap(find.byTooltip('字号'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('默认'));
    await tester.pumpAndSettle();
    expect(runStyle(tester).fontSize, theme.textTheme.bodyMedium?.fontSize);

    await selectAllBody(tester);
    await tester.tap(find.byTooltip('字体颜色'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('默认'));
    await tester.pumpAndSettle();
    expect(runStyle(tester).color, theme.textTheme.bodyMedium?.color);
  });

  testWidgets('取消加粗后恢复基础字重', (tester) async {
    await pumpEditor(tester, blocks: const [
      ParagraphBlock(inlines: [NoteInline(text: '文本', bold: true)]),
    ]);
    expect(runStyle(tester).fontWeight, FontWeight.bold);

    await selectAllBody(tester);
    await tester.tap(find.byTooltip('加粗'));
    await tester.pumpAndSettle();

    final theme = themeOf(tester);
    expect(runStyle(tester).fontWeight, theme.textTheme.bodyMedium?.fontWeight);
  });
}