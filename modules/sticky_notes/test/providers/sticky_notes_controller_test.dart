import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/data/sticky_notes_repository.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_note.dart';
import 'package:sticky_notes_module/features/sticky_notes/providers/sticky_notes_controller.dart';

import '../helpers/memory_storage_service.dart';

void main() {
  late MemoryStorageService storage;
  late StickyNotesRepository repository;
  late StickyNotesController controller;
  final base = DateTime(2026, 9, 1, 9);

  StickyNote note(
    String id, {
    String? categoryId,
    bool isPinned = false,
    DateTime? updatedAt,
  }) =>
      StickyNote(
        id: id,
        title: id,
        categoryId: categoryId,
        isPinned: isPinned,
        createdAt: base,
        updatedAt: updatedAt ?? base,
      );

  setUp(() {
    storage = MemoryStorageService();
    repository = StickyNotesRepository(storageService: storage);
    controller = StickyNotesController(repository: repository);
  });

  group('StickyNotesController', () {
    test('load 加载已存数据并标记 loaded', () async {
      await repository.saveAll([note('a')]);
      await controller.load();
      expect(controller.loaded, true);
      expect(controller.notes.length, 1);
    });

    test('load 幂等：不重复加载覆盖内存数据', () async {
      await controller.load();
      await controller.add(note('a'));
      await controller.load();
      expect(controller.notes.length, 1);
    });

    test('add / update / delete 即时持久化', () async {
      await controller.add(note('a'));
      expect((await repository.loadAll()).length, 1);

      await controller.update(note('a', categoryId: 'work'));
      expect((await repository.loadAll()).first.categoryId, 'work');

      await controller.delete('a');
      expect(await repository.loadAll(), isEmpty);
    });

    test('togglePin 置顶记录时间，取消置顶清空时间', () async {
      await controller.add(note('a'));

      await controller.togglePin('a');
      var stored = (await repository.loadAll()).first;
      expect(stored.isPinned, true);
      expect(stored.pinnedAt, isNotNull);

      await controller.togglePin('a');
      stored = (await repository.loadAll()).first;
      expect(stored.isPinned, false);
      expect(stored.pinnedAt, isNull);
    });

    test('togglePin 对不存在的 id 无操作', () async {
      await controller.togglePin('missing');
      expect(controller.notes, isEmpty);
    });

    test('clearCategory 将指定分类便签置为无分类', () async {
      await controller.add(note('a', categoryId: 'work'));
      await controller.add(note('b', categoryId: 'life'));
      await controller.clearCategory('work');

      final stored = await repository.loadAll();
      expect(stored.firstWhere((e) => e.id == 'a').categoryId, isNull);
      expect(stored.firstWhere((e) => e.id == 'b').categoryId, 'life');
    });

    test('import 按 id 合并，updatedAt 较新者为准', () async {
      await controller.add(note('a'));
      await controller.add(note('b'));

      final newer = note(
        'a',
        categoryId: 'work',
        updatedAt: base.add(const Duration(days: 1)),
      );
      await controller.import([newer, note('c')]);

      expect(controller.notes.length, 3);
      expect(
        controller.notes.firstWhere((e) => e.id == 'a').categoryId,
        'work',
      );
    });

    test('import 保留本地较新版本', () async {
      await controller.add(
        note('a', updatedAt: base.add(const Duration(days: 2))),
      );
      await controller.import([note('a', categoryId: 'work')]);
      expect(controller.notes.first.categoryId, isNull);
    });

    test('setCategoryFilter 更新筛选并通知', () {
      var notified = 0;
      controller.addListener(() => notified++);

      controller.setCategoryFilter('work');
      expect(controller.categoryFilter, 'work');
      expect(notified, 1);

      controller.setCategoryFilter(null);
      expect(controller.categoryFilter, isNull);
      expect(notified, 2);
    });
  });
}
