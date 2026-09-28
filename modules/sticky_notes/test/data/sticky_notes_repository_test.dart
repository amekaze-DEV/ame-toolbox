import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/data/sticky_notes_repository.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_block.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_note.dart';

import '../helpers/memory_storage_service.dart';

void main() {
  group('StickyNotesRepository', () {
    late MemoryStorageService storage;
    late StickyNotesRepository repository;

    final createdAt = DateTime(2026, 9, 1, 9);
    final updatedAt = DateTime(2026, 9, 2, 9);

    StickyNote buildNote(String id, String title) => StickyNote(
          id: id,
          title: title,
          content: const [
            ParagraphBlock(inlines: [NoteInline(text: '正文')]),
          ],
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

    setUp(() {
      storage = MemoryStorageService();
      repository = StickyNotesRepository(storageService: storage);
    });

    test('首次 loadAll 返回空列表', () async {
      expect(await repository.loadAll(), isEmpty);
    });

    test('saveAll/loadAll 往返（含 schemaVersion）', () async {
      await repository.saveAll([
        buildNote('a', '甲'),
        buildNote('b', '乙'),
      ]);

      final stored = await storage.loadData('module_sticky_notes_notes');
      expect(stored, isNotNull);
      expect(stored!['schemaVersion'], 1);

      final notes = await repository.loadAll();
      expect(notes.length, 2);
      expect(notes[0].id, 'a');
      expect(notes[0].content.length, 1);
      expect((notes[0].content.first as ParagraphBlock).inlines.first.text, '正文');
      expect(notes[1].title, '乙');
    });

    test('upsert 追加与替换', () async {
      await repository.upsert(buildNote('a', '甲'));
      expect((await repository.loadAll()).length, 1);

      await repository.upsert(buildNote('a', '甲改'));
      final replaced = await repository.loadAll();
      expect(replaced.length, 1);
      expect(replaced.first.title, '甲改');

      await repository.upsert(buildNote('b', '乙'));
      expect((await repository.loadAll()).length, 2);
    });

    test('delete 按 id 删除', () async {
      await repository.saveAll([
        buildNote('a', '甲'),
        buildNote('b', '乙'),
      ]);
      await repository.delete('a');

      final notes = await repository.loadAll();
      expect(notes.length, 1);
      expect(notes.first.id, 'b');
    });

    test('clearAll 清空', () async {
      await repository.saveAll([buildNote('a', '甲')]);
      await repository.clearAll();
      expect(await repository.loadAll(), isEmpty);
    });
  });
}
