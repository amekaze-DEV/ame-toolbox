import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/data/sticky_notes_config_repository.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_category.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_sort_mode.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_notes_config.dart';

import '../helpers/memory_storage_service.dart';

void main() {
  group('StickyNotesConfigRepository', () {
    late MemoryStorageService storage;
    late StickyNotesConfigRepository repository;

    setUp(() {
      storage = MemoryStorageService();
      repository = StickyNotesConfigRepository(storageService: storage);
    });

    test('首次 load 写入默认配置并返回', () async {
      final config = await repository.load();
      expect(config.categories.length, 3);
      expect(config.defaultSortMode, NoteSortMode.updatedDesc);

      final stored = await storage.loadData('module_sticky_notes_config');
      expect(stored, isNotNull);
      expect(stored!['schemaVersion'], 1);
    });

    test('再次 load 读取已保存配置', () async {
      await repository.load();
      await repository.save(
        const StickyNotesConfig(
          categories: [
            NoteCategory(
                id: 'category_x', name: 'X', colorValue: 0xFF000000, displayOrder: 0),
          ],
          defaultSortMode: NoteSortMode.titleAsc,
        ),
      );

      final restored = await repository.load();
      expect(restored.categories.length, 1);
      expect(restored.categories.first.id, 'category_x');
      expect(restored.defaultSortMode, NoteSortMode.titleAsc);
    });

    test('reset 恢复默认配置', () async {
      await repository.save(
        const StickyNotesConfig(
          categories: [],
          defaultSortMode: NoteSortMode.createdDesc,
        ),
      );

      final resetted = await repository.reset();
      expect(resetted.categories.length, 3);
      expect(resetted.defaultSortMode, NoteSortMode.updatedDesc);

      final reloaded = await repository.load();
      expect(reloaded.categories.length, 3);
    });
  });
}
