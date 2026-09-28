import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_block.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_image_attachment.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';
import 'package:sticky_notes_module/features/sticky_notes/services/note_rich_text_parser.dart';

void main() {
  const parser = NoteRichTextParser();
  final theme = ThemeData();

  ImageBlock imageBlock() => ImageBlock(
        attachment: NoteImageAttachment(
          id: 'img',
          dataBase64: 'AAAA',
          createdAt: DateTime(2026, 9, 1),
        ),
      );

  group('NoteRichTextParser.toPlainText', () {
    test('块间换行、行内拼接、空块与图片块忽略', () {
      final blocks = [
        const ParagraphBlock(inlines: [NoteInline(text: '标题')]),
        const ParagraphBlock(inlines: []),
        imageBlock(),
        const ParagraphBlock(
            inlines: [NoteInline(text: '第一句'), NoteInline(text: '第二句')]),
      ];
      expect(parser.toPlainText(blocks), '标题\n第一句第二句');
    });

    test('全空块返回空字符串', () {
      const blocks = [ParagraphBlock(inlines: [])];
      expect(parser.toPlainText(blocks), '');
    });
  });

  group('NoteRichTextParser.visibleBlocks', () {
    test('过滤空文本块但保留图片块', () {
      final blocks = [
        const ParagraphBlock(inlines: [NoteInline(text: 'x')]),
        const ParagraphBlock(inlines: []),
        imageBlock(),
      ];
      final visible = parser.visibleBlocks(blocks);
      expect(visible.length, 2);
      expect(visible[0], isA<ParagraphBlock>());
      expect(visible[1], isA<ImageBlock>());
    });
  });

  group('NoteRichTextParser.styleForBlock', () {
    test('文本块使用 bodyMedium', () {
      expect(
        parser.styleForBlock(const ParagraphBlock(inlines: []), theme),
        theme.textTheme.bodyMedium,
      );
    });

    test('图片块无文本样式', () {
      expect(parser.styleForBlock(imageBlock(), theme), isNull);
    });
  });

  group('NoteRichTextParser.inlineStyleOf', () {
    // 显式给定字号：裸 ThemeData 的 textTheme 可能不含 fontSize。
    final base = theme.textTheme.bodyMedium!.copyWith(fontSize: 14);

    test('字号为绝对值覆盖基础字号', () {
      expect(
        parser
            .inlineStyleOf(const NoteInline(text: 'x', fontSize: 24), base, theme)
            .fontSize,
        24,
      );
      expect(
        parser.inlineStyleOf(const NoteInline(text: 'x'), base, theme).fontSize,
        14,
      );
    });

    test('自定义颜色覆盖基础色，未设置时继承', () {
      expect(
        parser
            .inlineStyleOf(
              const NoteInline(text: 'x', colorValue: 0xFFED7D31),
              base,
              theme,
            )
            .color,
        const Color(0xFFED7D31),
      );
      expect(
        parser.inlineStyleOf(const NoteInline(text: 'x'), base, theme).color,
        base.color,
      );
    });

    test('加粗 / 斜体 / 下划线 / 删除线', () {
      final style = parser.inlineStyleOf(
        const NoteInline(
          text: 'x',
          bold: true,
          italic: true,
          underline: true,
          strikethrough: true,
        ),
        base,
        theme,
      );
      expect(style.fontWeight, FontWeight.bold);
      expect(style.fontStyle, FontStyle.italic);
      expect(
        style.decoration,
        TextDecoration.combine(
          [TextDecoration.underline, TextDecoration.lineThrough],
        ),
      );
    });

    test('无下划线/删除线时清除装饰', () {
      expect(
        parser.inlineStyleOf(const NoteInline(text: 'x'), base, theme).decoration,
        TextDecoration.none,
      );
    });
  });

  group('NoteRichTextParser.buildTextSpan', () {
    test('按 runs 生成子 span 且基础样式来自 textTheme', () {
      final span = parser.buildTextSpan(
        const ParagraphBlock(inlines: []),
        const [NoteInline(text: 'a'), NoteInline(text: 'b', bold: true)],
        theme,
      );
      expect(span.style, theme.textTheme.bodyMedium);
      expect(span.children!.length, 2);
      expect((span.children![0] as TextSpan).text, 'a');
      expect(
        (span.children![1] as TextSpan).style!.fontWeight,
        FontWeight.bold,
      );
    });
  });
}