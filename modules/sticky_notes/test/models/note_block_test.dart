import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_block.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_image_attachment.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';

/// 字段级比对行内元素列表。
void expectInlines(List<NoteInline> actual, List<NoteInline> expected) {
  expect(actual.length, expected.length);
  for (var i = 0; i < actual.length; i++) {
    expect(actual[i].text, expected[i].text);
    expect(actual[i].bold, expected[i].bold);
    expect(actual[i].italic, expected[i].italic);
    expect(actual[i].underline, expected[i].underline);
    expect(actual[i].strikethrough, expected[i].strikethrough);
    expect(actual[i].fontSize, expected[i].fontSize);
    expect(actual[i].colorValue, expected[i].colorValue);
    expect(actual[i].link, expected[i].link);
  }
}

void main() {
  const inlines = [NoteInline(text: '文本', bold: true)];

  group('NoteBlock JSON 往返与类型分发', () {
    test('ParagraphBlock（文本块）', () {
      final json = ParagraphBlock(inlines: inlines).toJson();
      expect(json['type'], 'paragraph');
      final restored = NoteBlock.fromJson(json);
      expect(restored, isA<ParagraphBlock>());
      expectInlines(restored.inlines, inlines);
    });

    test('ImageBlock 含图片载荷且 inlines 为空', () {
      final json = ImageBlock(
        attachment: NoteImageAttachment(
          id: 'img_1',
          dataBase64: 'AAAA',
          createdAt: DateTime(2026, 9, 1),
        ),
      ).toJson();
      expect(json['type'], 'image');
      final restored = NoteBlock.fromJson(json);
      expect(restored, isA<ImageBlock>());
      expect(restored.inlines, isEmpty);
      expect((restored as ImageBlock).attachment.id, 'img_1');
      expect(restored.attachment.dataBase64, 'AAAA');
    });

    test('已废弃的块类型降级为文本块并保留文本', () {
      for (final legacy in NoteBlock.legacyTypeNames) {
        final restored = NoteBlock.fromJson({
          'type': legacy,
          'level': 2,
          'checked': true,
          'inlines': ParagraphBlock(inlines: inlines).toJson()['inlines'],
        });
        expect(restored, isA<ParagraphBlock>(),
            reason: 'legacy type $legacy');
        expectInlines(restored.inlines, inlines);
      }
    });

    test('多行内样式组合往返', () {
      const mixed = [
        NoteInline(text: '普通'),
        NoteInline(text: '粗', bold: true),
        NoteInline(text: '斜', italic: true),
        NoteInline(text: '下', underline: true),
        NoteInline(text: '删', strikethrough: true),
        NoteInline(text: '大', fontSize: 24),
        NoteInline(text: '红', colorValue: 0xFFED7D31),
        NoteInline(text: '链接', link: 'https://example.com'),
      ];
      final restored =
          NoteBlock.fromJson(ParagraphBlock(inlines: mixed).toJson());
      expectInlines(restored.inlines, mixed);
    });

    test('inlines 缺失时为空列表', () {
      final restored = NoteBlock.fromJson({'type': 'paragraph'});
      expect(restored.inlines, isEmpty);
    });

    test('未知 type 抛出 ArgumentError', () {
      expect(
        () => NoteBlock.fromJson({'type': 'unknown', 'inlines': <dynamic>[]}),
        throwsArgumentError,
      );
    });
  });
}