import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';

void main() {
  group('NoteInline', () {
    test('默认样式为无格式文本', () {
      const inline = NoteInline(text: '普通');
      expect(inline.bold, false);
      expect(inline.italic, false);
      expect(inline.underline, false);
      expect(inline.strikethrough, false);
      expect(inline.fontSize, isNull);
      expect(inline.colorValue, isNull);
      expect(inline.link, isNull);
      expect(inline.hasInlineStyle, false);
    });

    test('JSON 往返（含全部行内样式与链接）', () {
      const inline = NoteInline(
        text: '链接文本',
        bold: true,
        italic: true,
        underline: true,
        strikethrough: true,
        fontSize: 24,
        colorValue: 0xFFED7D31,
        link: 'https://example.com',
      );
      final json = inline.toJson();
      expect(json['link'], 'https://example.com');
      expect(json['fontSize'], 24.0);
      expect(json['colorValue'], 0xFFED7D31);

      final restored = NoteInline.fromJson(json);
      expect(restored.text, '链接文本');
      expect(restored.bold, true);
      expect(restored.italic, true);
      expect(restored.underline, true);
      expect(restored.strikethrough, true);
      expect(restored.fontSize, 24.0);
      expect(restored.colorValue, 0xFFED7D31);
      expect(restored.link, 'https://example.com');
      expect(restored.hasInlineStyle, true);
    });

    test('默认样式不输出可选字段', () {
      const inline = NoteInline(text: 'x');
      final json = inline.toJson();
      expect(json.containsKey('link'), false);
      expect(json.containsKey('underline'), false);
      expect(json.containsKey('fontSize'), false);
      expect(json.containsKey('colorValue'), false);
    });

    test('非法字号 / 颜色归一化为 null', () {
      final restored = NoteInline.fromJson(const {
        'text': 'x',
        'fontSize': -3,
        'colorValue': 'red',
      });
      expect(restored.fontSize, isNull);
      expect(restored.colorValue, isNull);

      final weird = NoteInline.fromJson(const {
        'text': 'x',
        'fontSize': 'large',
        'colorValue': 12.5,
      });
      expect(weird.fontSize, isNull);
      expect(weird.colorValue, isNull);
    });

    test('copyWith 仅更新指定字段', () {
      const inline = NoteInline(text: 'x');
      final updated = inline.copyWith(bold: true, fontSize: 18);
      expect(updated.text, 'x');
      expect(updated.bold, true);
      expect(updated.italic, false);
      expect(updated.fontSize, 18);
      expect(updated.colorValue, isNull);
    });

    test('copyWith 可用 clear 标志置空字号与颜色', () {
      const inline = NoteInline(
        text: 'x',
        fontSize: 32,
        colorValue: 0xFF4472C4,
      );
      final cleared = inline.copyWith(
        clearFontSize: true,
        clearColorValue: true,
      );
      expect(cleared.fontSize, isNull);
      expect(cleared.colorValue, isNull);
      // 未传 clear 时保持原值。
      expect(inline.copyWith(bold: true).fontSize, 32);
      expect(inline.copyWith(bold: true).colorValue, 0xFF4472C4);
    });

    test('值相等语义覆盖全部字段', () {
      const a = NoteInline(
        text: 'x',
        bold: true,
        underline: true,
        fontSize: 20,
        colorValue: 0xFF000000,
      );
      const b = NoteInline(
        text: 'x',
        bold: true,
        underline: true,
        fontSize: 20,
        colorValue: 0xFF000000,
      );
      const c = NoteInline(text: 'x', bold: true);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, false);
    });
  });
}