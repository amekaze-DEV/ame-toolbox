import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_block.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_image_attachment.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';
import 'package:sticky_notes_module/features/sticky_notes/widgets/note_rich_text_editor.dart';

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

  testWidgets('工具栏加粗切换当前文本块样式', (tester) async {
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
    expect(result![0].inlines.first.bold, true);
  });

  testWidgets('工具栏下划线切换当前文本块样式', (tester) async {
    List<NoteBlock>? result;
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: const [ParagraphBlock(inlines: [NoteInline(text: '文本')])],
          onChanged: (value) => result = value,
        ),
      ),
    );

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

  testWidgets('正文内容区以独立填充容器呈现', (tester) async {
    await tester.pumpWidget(
      wrap(
        NoteRichTextEditor(
          blocks: const [ParagraphBlock(inlines: [NoteInline(text: '文本')])],
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(NoteRichTextEditor)));
    final decorations = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(NoteRichTextEditor),
            matching: find.byType(Container),
          ),
        )
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .toList();

    expect(
      decorations.any(
        (decoration) =>
            decoration.border != null &&
            decoration.color == theme.colorScheme.surfaceContainerLow &&
            decoration.borderRadius == BorderRadius.circular(12),
      ),
      isTrue,
    );
  });
}