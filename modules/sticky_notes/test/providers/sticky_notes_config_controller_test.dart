import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/data/sticky_notes_config_repository.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_sort_mode.dart';
import 'package:sticky_notes_module/features/sticky_notes/providers/sticky_notes_config_controller.dart';

import '../helpers/memory_storage_service.dart';

void main() {
  late MemoryStorageService storage;
  late StickyNotesConfigRepository repository;
  late StickyNotesConfigController controller;

  setUp(() {
    storage = MemoryStorageService();
    repository = StickyNotesConfigRepository(storageService: storage);
    controller = StickyNotesConfigController(repository);
  });

  group('StickyNotesConfigController', () {
    test('load 首次写入默认配置', () async {
      await controller.load();
      expect(controller.loaded, true);
      expect(controller.config.categories.length, 3);
      expect(controller.config.defaultSortMode, NoteSortMode.updatedDesc);
    });

    test('addCategory 使用 category_ 前缀并递增 displayOrder', () async {
      await controller.load();
      await controller.addCategory('灵感', colorValue: 0xFF00897B);

      final added = controller.config.categories.last;
      expect(added.id.startsWith('category_'), true);
      expect(added.name, '灵感');
      expect(added.displayOrder, 3);

      final stored = await repository.load();
      expect(stored.categories.length, 4);
    });

    test('updateCategory 按 id 更新', () async {
      await controller.load();
      final target = controller.config.categories.first;
      await controller.updateCategory(target.copyWith(name: '项目'));
      expect(controller.config.categories.first.name, '项目');
      expect(controller.config.categories.first.id, target.id);
    });

    test('deleteCategory 移除分类', () async {
      await controller.load();
      await controller.deleteCategory('life');
      expect(controller.config.categories.length, 2);
      expect(
        controller.config.categories.any((c) => c.id == 'life'),
        false,
      );
    });

    test('reorderCategories 重排并刷新 displayOrder', () async {
      await controller.load();
      await controller.reorderCategories(0, 2);

      final categories = controller.config.categories;
      expect(categories.map((c) => c.id).toList(), ['life', 'other', 'work']);
      expect(categories.map((c) => c.displayOrder).toList(), [0, 1, 2]);
    });

    test('setDefaultSortMode 持久化', () async {
      await controller.load();
      await controller.setDefaultSortMode(NoteSortMode.titleAsc);
      expect(controller.config.defaultSortMode, NoteSortMode.titleAsc);

      final stored = await repository.load();
      expect(stored.defaultSortMode, NoteSortMode.titleAsc);
    });

    test('reset 恢复默认配置', () async {
      await controller.load();
      await controller.deleteCategory('life');
      await controller.reset();
      expect(controller.config.categories.length, 3);
    });
  });
}
