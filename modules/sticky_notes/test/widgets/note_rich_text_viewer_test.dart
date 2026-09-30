import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_block.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_image_attachment.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';
import 'package:sticky_notes_module/features/sticky_notes/widgets/note_rich_text_viewer.dart';

import '../helpers/rich_text_spans.dart';

/// 1x1 透明 PNG（base64）。
const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==';

Widget wrap(Widget child) => InputModeScope(
      mode: InputMode.touch,
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('空正文展示占位文案', (tester) async {
    await tester.pumpWidget(
      wrap(const NoteRichTextViewer(blocks: [ParagraphBlock(inlines: [])])),
    );
    await tester.pumpAndSettle();

    expect(find.text('暂无正文'), findsOneWidget);
  });

  testWidgets('按行内样式渲染文本且无输入框', (tester) async {
    await tester.pumpWidget(
      wrap(
        const NoteRichTextViewer(
          blocks: [
            ParagraphBlock(
              inlines: [
                NoteInline(text: '普通'),
                NoteInline(text: '粗', bold: true),
                NoteInline(text: '下', underline: true),
                NoteInline(text: '大', fontSize: 26),
                NoteInline(text: '彩', colorValue: 0xFFED7D31),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('普通'), findsOneWidget);
    final span = runsSpanIn(tester, find.byType(NoteRichTextViewer), contains: '普通');
    expect(span.children!.length, 5);
    expect((span.children![1] as TextSpan).style!.fontWeight, FontWeight.bold);
    expect(
      (span.children![2] as TextSpan).style!.decoration,
      TextDecoration.underline,
    );
    expect((span.children![3] as TextSpan).style!.fontSize, 26);
    expect(
      (span.children![4] as TextSpan).style!.color,
      const Color(0xFFED7D31),
    );
  });

  testWidgets('图片块只读展示且不显示删除入口', (tester) async {
    await tester.pumpWidget(
      wrap(
        NoteRichTextViewer(
          blocks: [
            ImageBlock(
              attachment: NoteImageAttachment(
                id: 'img_1',
                dataBase64: _pngBase64,
                createdAt: DateTime(2026, 9, 1),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byTooltip('删除图片'), findsNothing);
  });

  testWidgets('空文本块不渲染且图片块恒可见', (tester) async {
    await tester.pumpWidget(
      wrap(
        const NoteRichTextViewer(
          blocks: [ParagraphBlock(inlines: [])],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('暂无正文'), findsOneWidget);
  });
}