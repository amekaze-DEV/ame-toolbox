import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_attachment.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_block.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_image_attachment.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_note.dart';

/// 构造图片载荷（base64 内容对断言无关紧要）。
NoteImageAttachment imageAttachment(String id) => NoteImageAttachment(
      id: id,
      dataBase64: 'AAAA',
      createdAt: DateTime(2026, 9, 1, 10),
    );

void main() {
  final createdAt = DateTime(2026, 9, 1, 10, 30);
  final updatedAt = DateTime(2026, 9, 2, 8);

  group('StickyNote', () {
    test('完整 JSON 往返（图文正文 + 置顶 + 分类）', () {
      final note = StickyNote(
        id: 'note_1',
        title: '购物清单',
        content: [
          const ParagraphBlock(inlines: [NoteInline(text: '本周')]),
          ImageBlock(attachment: imageAttachment('img_1')),
          const ParagraphBlock(
            inlines: [NoteInline(text: '正文', bold: true)],
          ),
        ],
        categoryId: 'life',
        isPinned: true,
        pinnedAt: updatedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final restored = StickyNote.fromJson(note.toJson());

      expect(restored.id, 'note_1');
      expect(restored.title, '购物清单');
      expect(restored.content.length, 3);
      expect(restored.content[0], isA<ParagraphBlock>());
      expect(restored.content[1], isA<ImageBlock>());
      expect(restored.content[2], isA<ParagraphBlock>());
      expect((restored.content[2] as ParagraphBlock).inlines.first.bold, true);
      expect(restored.categoryId, 'life');
      expect(restored.isPinned, true);
      expect(restored.pinnedAt, updatedAt);
      expect(restored.createdAt, createdAt);
      expect(restored.updatedAt, updatedAt);
    });

    test('旧格式独立图片附件迁移为正文末尾图片块', () {
      final json = <String, dynamic>{
        'id': 'note_legacy',
        'title': '旧便签',
        'content': [
          const ParagraphBlock(inlines: [NoteInline(text: '旧正文')]).toJson(),
        ],
        'images': [imageAttachment('img_0').toJson()],
        'isPinned': false,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

      final restored = StickyNote.fromJson(json);
      expect(restored.content.length, 2);
      expect(restored.content[0], isA<ParagraphBlock>());
      expect(restored.content[1], isA<ImageBlock>());
      expect((restored.content[1] as ImageBlock).attachment.id, 'img_0');
      // 迁移后重新序列化不再包含 images 字段。
      expect(restored.toJson().containsKey('images'), false);
    });

    test('旧块类型正文反序列化不报错且降级为文本块', () {
      final json = <String, dynamic>{
        'id': 'note_v1',
        'title': '旧块类型',
        'content': [
          {
            'type': 'heading',
            'level': 1,
            'inlines': [const NoteInline(text: '标题').toJson()],
          },
          {
            'type': 'checkList',
            'checked': true,
            'inlines': [const NoteInline(text: '待办').toJson()],
          },
        ],
        'isPinned': false,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

      final restored = StickyNote.fromJson(json);
      expect(restored.content.length, 2);
      expect(restored.content[0], isA<ParagraphBlock>());
      expect(restored.content[1], isA<ParagraphBlock>());
      expect(restored.content[0].inlines.first.text, '标题');
      expect(restored.content[1].inlines.first.text, '待办');
    });

    test('最简 JSON 往返与默认值', () {
      final note = StickyNote(
          id: 'n', title: 't', createdAt: createdAt, updatedAt: updatedAt);
      final json = note.toJson();
      expect(json.containsKey('categoryId'), false);
      expect(json.containsKey('pinnedAt'), false);
      expect(json.containsKey('images'), false);

      final restored = StickyNote.fromJson(json);
      expect(restored.content, isEmpty);
      expect(restored.categoryId, isNull);
      expect(restored.isPinned, false);
      expect(restored.pinnedAt, isNull);
    });

    test('copyWith 仅更新指定字段', () {
      final note = StickyNote(
          id: 'n', title: 't', createdAt: createdAt, updatedAt: updatedAt);
      final edited = note.copyWith(
        title: '新标题',
        isPinned: true,
        pinnedAt: updatedAt,
        updatedAt: updatedAt,
      );
      expect(edited.id, 'n');
      expect(edited.title, '新标题');
      expect(edited.isPinned, true);
      expect(edited.pinnedAt, updatedAt);
      expect(edited.createdAt, createdAt);
    });

    test('附件元数据 JSON 往返', () {
      final attachment = NoteAttachment(
        id: 'att_1',
        fileName: '报告.pdf',
        sizeBytes: 2048,
        mimeType: 'application/pdf',
        createdAt: createdAt,
      );
      final note = StickyNote(
        id: 'n',
        title: 't',
        attachments: [attachment],
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final restored = StickyNote.fromJson(note.toJson());

      expect(restored.attachments, hasLength(1));
      expect(restored.attachments.single.id, 'att_1');
      expect(restored.attachments.single.fileName, '报告.pdf');
      expect(restored.attachments.single.sizeBytes, 2048);
      expect(restored.attachments.single.mimeType, 'application/pdf');
      expect(restored.attachments.single.createdAt, createdAt);
    });

    test('无附件时不输出 attachments 字段且回读为空列表', () {
      final note = StickyNote(
          id: 'n', title: 't', createdAt: createdAt, updatedAt: updatedAt);

      expect(note.toJson().containsKey('attachments'), false);
      expect(StickyNote.fromJson(note.toJson()).attachments, isEmpty);
    });

    test('copyWith 更新附件列表，未指定时保留原值', () {
      final attachment = NoteAttachment(
        id: 'att_1',
        fileName: 'a.txt',
        sizeBytes: 1,
        createdAt: createdAt,
      );
      final note = StickyNote(
        id: 'n',
        title: 't',
        attachments: [attachment],
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(note.copyWith(title: 'x').attachments, hasLength(1));
      expect(note.copyWith(attachments: const []).attachments, isEmpty);
    });

    test('copyWith 置空 categoryId 与 pinnedAt', () {
      final note = StickyNote(
        id: 'n',
        title: 't',
        categoryId: 'work',
        isPinned: true,
        pinnedAt: updatedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final cleared = note.copyWith(
        isPinned: false,
        clearCategoryId: true,
        clearPinnedAt: true,
      );
      expect(cleared.categoryId, isNull);
      expect(cleared.pinnedAt, isNull);
      expect(cleared.isPinned, false);
    });
  });
}