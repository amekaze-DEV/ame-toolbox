import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_category.dart';

void main() {
  group('NoteCategory', () {
    test('JSON 往返', () {
      const category = NoteCategory(
        id: 'category_a',
        name: '灵感',
        colorValue: 0xFF00897B,
        displayOrder: 3,
      );
      final restored = NoteCategory.fromJson(category.toJson());
      expect(restored.id, 'category_a');
      expect(restored.name, '灵感');
      expect(restored.colorValue, 0xFF00897B);
      expect(restored.displayOrder, 3);
    });

    test('copyWith 仅更新指定字段', () {
      const category = NoteCategory(
        id: 'work',
        name: '工作',
        colorValue: 0xFF1565C0,
        displayOrder: 0,
      );
      final updated = category.copyWith(name: '项目', displayOrder: 2);
      expect(updated.id, 'work');
      expect(updated.name, '项目');
      expect(updated.colorValue, 0xFF1565C0);
      expect(updated.displayOrder, 2);
    });
  });
}
