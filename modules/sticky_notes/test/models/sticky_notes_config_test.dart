import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_category.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_sort_mode.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_notes_config.dart';

void main() {
  group('StickyNotesConfig', () {
    test('默认配置含 3 个内置分类与默认排序', () {
      const config = StickyNotesConfig();
      expect(config.categories.length, 3);
      expect(config.categories[0].id, 'work');
      expect(config.categories[1].id, 'life');
      expect(config.categories[2].id, 'other');
      expect(config.defaultSortMode, NoteSortMode.updatedDesc);
    });

    test('JSON 往返（含 schemaVersion）', () {
      const config = StickyNotesConfig(
        categories: [
          NoteCategory(
              id: 'category_a', name: '灵感', colorValue: 0xFF00897B, displayOrder: 0),
        ],
        defaultSortMode: NoteSortMode.titleAsc,
      );
      final json = config.toJson();
      expect(json['schemaVersion'], 1);
      expect(json['defaultSortMode'], 'titleAsc');

      final restored = StickyNotesConfig.fromJson(json);
      expect(restored.categories.length, 1);
      expect(restored.categories.first.name, '灵感');
      expect(restored.defaultSortMode, NoteSortMode.titleAsc);
    });

    test('缺省字段回退默认值', () {
      final restored = StickyNotesConfig.fromJson(<String, dynamic>{});
      expect(restored.categories.length, 3);
      expect(restored.defaultSortMode, NoteSortMode.updatedDesc);
    });

    test('显式空分类列表保持为空（默认分类亦可删除）', () {
      final restored =
          StickyNotesConfig.fromJson({'categories': <dynamic>[]});
      expect(restored.categories, isEmpty);
    });

    test('copyWith 仅更新指定字段', () {
      const config = StickyNotesConfig();
      final updated =
          config.copyWith(defaultSortMode: NoteSortMode.createdDesc);
      expect(updated.defaultSortMode, NoteSortMode.createdDesc);
      expect(updated.categories.length, 3);
    });
  });
}
