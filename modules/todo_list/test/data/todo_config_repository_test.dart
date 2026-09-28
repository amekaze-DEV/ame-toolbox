import 'package:flutter_test/flutter_test.dart';
import '../helpers/memory_storage_service.dart';
import 'package:todo_list_module/features/todo_list/data/todo_config_repository.dart';
import 'package:todo_list_module/features/todo_list/models/todo_category.dart';
import 'package:todo_list_module/features/todo_list/models/todo_config.dart';

void main() {
  group('TodoConfigRepository', () {
    late MemoryStorageService storage;
    late TodoConfigRepository repository;

    setUp(() {
      storage = MemoryStorageService();
      repository = TodoConfigRepository(storageService: storage);
    });

    test('首次 load 写入默认配置并返回', () async {
      final config = await repository.load();
      expect(config.categories.length, 3);
      expect(config.remindEnabled, true);

      // 验证已写入存储
      final stored = await storage.loadData('module_todo_list_config');
      expect(stored, isNotNull);
      expect(stored!['schemaVersion'], 1);
    });

    test('再次 load 读取已保存配置', () async {
      await repository.load();
      final custom = TodoConfig(
        categories: const [
          TodoCategory(id: 'x', name: 'X', colorValue: 0xFF000000, displayOrder: 0),
        ],
        remindEnabled: false,
        defaultRemindMinutes: 10,
        dailyTop: true,
      );
      await repository.save(custom);

      final restored = await repository.load();
      expect(restored.categories.length, 1);
      expect(restored.remindEnabled, false);
      expect(restored.defaultRemindMinutes, 10);
      expect(restored.dailyTop, true);
    });

    test('reset 恢复默认配置', () async {
      await repository.save(
        const TodoConfig(
          categories: [],
          remindEnabled: false,
          defaultRemindMinutes: 5,
          dailyTop: true,
        ),
      );

      final resetted = await repository.reset();
      expect(resetted.categories.length, 3);
      expect(resetted.remindEnabled, true);
      expect(resetted.dailyTop, false);
    });
  });
}