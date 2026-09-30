import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_block.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_image_attachment.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';
import 'package:sticky_notes_module/features/sticky_notes/widgets/note_rich_text_editor.dart';
import 'package:sticky_notes_module/features/sticky_notes/widgets/rich_text_editing_controller.dart';

/// 1x1 透明 PNG（base64）。
const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==';

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

/// 取正文编辑控制器。
RichTextEditingController bodyController(WidgetTester tester) {
  final editable = tester.widget<EditableText>(find.byType(EditableText));
  return editable.controller as RichTextEditingController;
}

/// 全选正文文本（模拟「先选中文本再调整格式」）。
Future<void> selectAllBody(WidgetTester tester) async {
  final controller = bodyController(tester);
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: controller.text.length,
  );
  await tester.pump();
}

void main() {
  NoteImageAttachment attachment(String id) => NoteImageAttachment(
        id: id,
        dataBase64: _pngBase64,
        createdAt: DateTime(2026, 9, 1),
      );

  testWidgets('空 blocks 时至少渲染一个文本块，且无块级操作入口', (tester) async {
    await tester.pumpWidget(
      wrap(NoteRichTextEditor(blocks: const [], onChanged: (_) {})),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('块格式'), findsNothing);
    expect(find.text('添加段落'), findsNothing);
  });

  testWidgets('未注入图片选择能力时不显示插入图片按钮', (tester) async {
    await tester.pumpWidget(
      wrap(NoteRichTextEditor(blocks: const [], onChanged: (_) {})),
    );

    expect(find.byTooltip('插入图片'), findsNothing);
  });

  testWidgets('正文框与标题同款描边样式且默认高度更大', (tester) async {
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: const [ParagraphBlock(inlines: [NoteInline(text: '文本')])],
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final decorator = tester.widget<InputDecorator>(
      find.byWidgetPredicate(
        (widget) =>
            widget is InputDecorator &&
            widget.decoration.labelText == '正文',
      ),
    );
    expect(decorator.decoration.border, isA<OutlineInputBorder>());

    final box = tester.widget<ConstrainedBox>(
      find
          .descendant(
            of: find.byType(InputDecorator),
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    expect(box.constraints.minHeight, NoteRichTextEditor.minBodyHeight);
  });

  testWidgets('折叠光标下点加粗不修改已输入文本', (tester) async {
    List<NoteBlock>? result;
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: const [ParagraphBlock(inlines: [NoteInline(text: '文本')])],
          onChanged: (value) => result = value,
        ),
      ),
    );

    await tester.tap(find.byTooltip('加粗'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result![0].inlines.first.bold, false);
    // 工具栏高亮表示「后续输入样式」已生效。
    final button = tester.widget<IconButton>(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == '加粗',
      ),
    );
    expect(button.isSelected, isTrue);
  });

  testWidgets('折叠光标下设定样式后，后续输入文本继承该样式', (tester) async {
    List<NoteBlock>? result;
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: const [ParagraphBlock(inlines: [])],
          onChanged: (value) => result = value,
        ),
      ),
    );

    await tester.tap(find.byTooltip('加粗'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '新增文本');
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result![0].inlines.first.text, '新增文本');
    expect(result![0].inlines.first.bold, true);
  });

  testWidgets('选中文本后点加粗只修改选中文本', (tester) async {
    List<NoteBlock>? result;
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: const [
            ParagraphBlock(inlines: [NoteInline(text: 'abcd')]),
          ],
          onChanged: (value) => result = value,
        ),
      ),
    );

    final controller = bodyController(tester);
    controller.selection = const TextSelection(
      baseOffset: 1,
      extentOffset: 3,
    );
    await tester.pump();

    await tester.tap(find.byTooltip('加粗'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    final inlines = result![0].inlines;
    expect(inlines.length, 3);
    expect(inlines[0].text, 'a');
    expect(inlines[0].bold, false);
    expect(inlines[1].text, 'bc');
    expect(inlines[1].bold, true);
    expect(inlines[2].text, 'd');
    expect(inlines[2].bold, false);
  });

  testWidgets('选中文本后点下划线生效', (tester) async {
    List<NoteBlock>? result;
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: const [ParagraphBlock(inlines: [NoteInline(text: '文本')])],
          onChanged: (value) => result = value,
        ),
      ),
    );

    await selectAllBody(tester);
    await tester.tap(find.byTooltip('下划线'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result![0].inlines.first.underline, true);
  });

  testWidgets('字号对话框按数值设定绝对字号', (tester) async {
    List<NoteBlock>? result;
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: const [ParagraphBlock(inlines: [NoteInline(text: '文本')])],
          onChanged: (value) => result = value,
        ),
      ),
    );

    await selectAllBody(tester);
    await tester.tap(find.byTooltip('字号'));
    await tester.pumpAndSettle();
    expect(find.text('字号'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);

    await tester.enterText(dialogTextField(), '28');
    await tester.pumpAndSettle();
    await tester.tap(find.text('应用'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result![0].inlines.first.fontSize, 28);
  });

  testWidgets('字号对话框「默认」清除字号', (tester) async {
    List<NoteBlock>? result;
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: const [
            ParagraphBlock(inlines: [NoteInline(text: '文本', fontSize: 28)]),
          ],
          onChanged: (value) => result = value,
        ),
      ),
    );

    await selectAllBody(tester);
    await tester.tap(find.byTooltip('字号'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('默认'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result![0].inlines.first.fontSize, isNull);
  });

  testWidgets('取色盘选择常用色并回传自定义色值', (tester) async {
    List<NoteBlock>? result;
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: const [ParagraphBlock(inlines: [NoteInline(text: '文本')])],
          onChanged: (value) => result = value,
        ),
      ),
    );

    await selectAllBody(tester);
    await tester.tap(find.byTooltip('字体颜色'));
    await tester.pumpAndSettle();
    expect(find.text('字体颜色'), findsOneWidget);
    expect(find.text('常用颜色'), findsOneWidget);

    await tester.tap(swatchOf(0xFFED7D31));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result![0].inlines.first.colorValue, 0xFFED7D31);
  });

  testWidgets('取色盘「默认」清除自定义颜色', (tester) async {
    List<NoteBlock>? result;
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: const [
            ParagraphBlock(
              inlines: [NoteInline(text: '文本', colorValue: 0xFFED7D31)],
            ),
          ],
          onChanged: (value) => result = value,
        ),
      ),
    );

    await selectAllBody(tester);
    await tester.tap(find.byTooltip('字体颜色'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('默认'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result![0].inlines.first.colorValue, isNull);
  });

  testWidgets('编辑文本回传并保留原有行内样式', (tester) async {
    List<NoteBlock>? result;
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: const [
            ParagraphBlock(inlines: [NoteInline(text: '旧', bold: true)]),
          ],
          onChanged: (value) => result = value,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '新文本');
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result![0].inlines.length, 1);
    expect(result![0].inlines.first.text, '新文本');
    expect(result![0].inlines.first.bold, true);
  });

  testWidgets('插入图片在当前块后生成图片块并补空文本块', (tester) async {
    List<NoteBlock>? result;
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: const [ParagraphBlock(inlines: [NoteInline(text: '甲')])],
          onChanged: (value) => result = value,
          onPickImages: () async => [attachment('img_1'), attachment('img_2')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('插入图片'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.length, 4);
    expect(result![0], isA<ParagraphBlock>());
    expect(result![1], isA<ImageBlock>());
    expect(result![2], isA<ImageBlock>());
    expect(result![3], isA<ParagraphBlock>());
  });

  testWidgets('图片块可删除并回传剩余块', (tester) async {
    List<NoteBlock>? result;
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: [
            const ParagraphBlock(inlines: [NoteInline(text: '甲')]),
            ImageBlock(attachment: attachment('img_1')),
          ],
          onChanged: (value) => result = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.byTooltip('删除图片'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.length, 1);
    expect(result![0], isA<ParagraphBlock>());
  });

  testWidgets('工具栏切换样式后正文保持输入焦点', (tester) async {
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: const [ParagraphBlock(inlines: [NoteInline(text: '文本')])],
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final focusNode =
        tester.widget<EditableText>(find.byType(EditableText)).focusNode;
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byTooltip('加粗'));
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('字号对话框确定后正文保持输入焦点', (tester) async {
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: const [ParagraphBlock(inlines: [NoteInline(text: '文本')])],
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final focusNode =
        tester.widget<EditableText>(find.byType(EditableText)).focusNode;
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byTooltip('字号'));
    await tester.pumpAndSettle();
    await tester.enterText(dialogTextField(), '28');
    await tester.pumpAndSettle();
    await tester.tap(find.text('应用'));
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('行高随字号变化，不再被基础行高强制固定', (tester) async {
    Future<double> heightOf(double? fontSize) async {
      await tester.pumpWidget(
        wrap(
          NoteRichTextEditor(
            // 每次使用不同 key，避免复用旧 State 导致 blocks 不生效。
            key: ValueKey(fontSize),
            blocks: [
              ParagraphBlock(
                inlines: [NoteInline(text: '甲', fontSize: fontSize)],
              ),
            ],
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(EditableText)).height;
    }

    final base = await heightOf(null);
    final large = await heightOf(48);

    // 未关闭 strut 时两行都会被强制为同一基础行高（约 24），大字号文本重叠。
    expect(large, greaterThan(base * 2));
  });
}