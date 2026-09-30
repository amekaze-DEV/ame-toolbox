import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/data/note_attachment_store.dart';
import 'package:sticky_notes_module/features/sticky_notes/data/sticky_notes_repository.dart';
import 'package:sticky_notes_module/features/sticky_notes/data/sync_snapshots.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_attachment.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_category.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_sort_mode.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_note.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_notes_config.dart';
import 'package:sticky_notes_module/features/sticky_notes/sticky_notes_module.dart';

import 'helpers/memory_storage_service.dart';

void main() {
  late MemoryStorageService storage;
  late StickyNotesModule module;
  final base = DateTime(2026, 9, 1, 9);

  NoteAttachment attachment(String id, {String fileName = 'a.txt'}) =>
      NoteAttachment(
        id: id,
        fileName: fileName,
        sizeBytes: 3,
        createdAt: base,
      );

  StickyNote note(
    String id, {
    String? title,
    List<NoteAttachment> attachments = const [],
    DateTime? updatedAt,
  }) =>
      StickyNote(
        id: id,
        title: title ?? id,
        attachments: attachments,
        createdAt: base,
        updatedAt: updatedAt ?? base,
      );

  setUp(() {
    storage = MemoryStorageService();
    module = StickyNotesModule();
    latestConfigSnapshot = null;
    latestNotesSnapshot = const [];
    attachmentBytesCache.clear();
  });

  tearDown(() => module.dispose());

  test('initialize 预载附件字节并统计便签数', () async {
    final store = NoteAttachmentStore(storageService: storage);
    await store.saveBytes('att_1', Uint8List.fromList([1, 2, 3]));
    await StickyNotesRepository(storageService: storage)
        .saveAll([note('n1', attachments: [attachment('att_1')])]);

    await module.initialize(storage);

    expect(module.summary.value, '1');
    expect(attachmentBytesCache['att_1'], Uint8List.fromList([1, 2, 3]));
  });

  test('exportData 导出配置、便签与附件字节', () async {
    final store = NoteAttachmentStore(storageService: storage);
    await store.saveBytes('att_1', Uint8List.fromList([1, 2, 3]));
    await StickyNotesRepository(storageService: storage)
        .saveAll([note('n1', attachments: [attachment('att_1')])]);
    await module.initialize(storage);

    final data = module.exportData();

    expect(data['module_sticky_notes_config'], isA<Map<String, dynamic>>());
    expect((data['module_sticky_notes_notes'] as List).length, 1);
    expect(
      (data['module_sticky_notes_attachments'] as Map<String, String>)['att_1'],
      base64Encode([1, 2, 3]),
    );
  });

  test('exportData 只导出被便签引用的附件字节', () async {
    final store = NoteAttachmentStore(storageService: storage);
    await store.saveBytes('att_used', Uint8List.fromList([1]));
    await store.saveBytes('att_orphan', Uint8List.fromList([2]));
    await StickyNotesRepository(storageService: storage)
        .saveAll([note('n1', attachments: [attachment('att_used')])]);
    await module.initialize(storage);

    final attachments =
        module.exportData()['module_sticky_notes_attachments']
            as Map<String, String>;

    expect(attachments.keys, ['att_used']);
  });

  test('importData 按 id 合并便签并落库附件字节', () async {
    await module.initialize(storage);
    final payload = <String, dynamic>{
      'module_sticky_notes_config': const StickyNotesConfig().toJson(),
      'module_sticky_notes_notes': [
        note(
          'n1',
          title: '远端',
          attachments: [attachment('att_r')],
          updatedAt: base.add(const Duration(days: 1)),
        ).toJson(),
      ],
      'module_sticky_notes_attachments': {
        'att_r': base64Encode([9, 9]),
      },
    };

    module.importData(payload);
    await pumpEventQueue();

    final stored = await StickyNotesRepository(storageService: storage).loadAll();
    expect(stored.single.title, '远端');
    expect(stored.single.attachments.single.id, 'att_r');
    expect(attachmentBytesCache['att_r'], Uint8List.fromList([9, 9]));
    final store = NoteAttachmentStore(storageService: storage);
    expect(await store.loadBytes('att_r'), Uint8List.fromList([9, 9]));
    // 同一轮同步内再次导出立即反映导入结果。
    expect(
      (module.exportData()['module_sticky_notes_notes'] as List).length,
      1,
    );
  });

  test('importData 保留本地较新便签与未引用的附件字节', () async {
    await StickyNotesRepository(storageService: storage).saveAll([
      note(
        'n1',
        title: '本地',
        attachments: [attachment('att_local')],
        updatedAt: base.add(const Duration(days: 2)),
      ),
    ]);
    await module.initialize(storage);

    module.importData(<String, dynamic>{
      'module_sticky_notes_notes': [
        note('n1', title: '远端', updatedAt: base).toJson(),
      ],
      'module_sticky_notes_attachments': {
        'att_orphan': base64Encode([7]),
      },
    });
    await pumpEventQueue();

    final stored = await StickyNotesRepository(storageService: storage).loadAll();
    expect(stored.single.title, '本地');
    // 未合并进来的附件字节不落库（避免孤儿）。
    final store = NoteAttachmentStore(storageService: storage);
    expect(await store.loadBytes('att_orphan'), isNull);
  });

  test('importData 整体替换配置', () async {
    await module.initialize(storage);
    final config = const StickyNotesConfig(
      categories: [
        NoteCategory(id: 'c1', name: '自定义', colorValue: 0xFF123456, displayOrder: 0),
      ],
      defaultSortMode: NoteSortMode.titleAsc,
    );

    module.importData(<String, dynamic>{
      'module_sticky_notes_config': config.toJson(),
    });
    await pumpEventQueue();

    final exported =
        module.exportData()['module_sticky_notes_config'] as Map<String, dynamic>;
    final restored = StickyNotesConfig.fromJson(exported);
    expect(restored.categories.single.name, '自定义');
    expect(restored.defaultSortMode, NoteSortMode.titleAsc);
  });

  test('export → import 往返：另一实例导入后数据一致', () async {
    final store = NoteAttachmentStore(storageService: storage);
    await store.saveBytes('att_1', Uint8List.fromList([5, 6]));
    await StickyNotesRepository(storageService: storage)
        .saveAll([note('n1', attachments: [attachment('att_1')])]);
    await module.initialize(storage);

    final exported = module.exportData();

    final otherStorage = MemoryStorageService();
    final other = StickyNotesModule();
    latestConfigSnapshot = null;
    latestNotesSnapshot = const [];
    attachmentBytesCache.clear();
    await other.initialize(otherStorage);
    other.importData(exported);
    await pumpEventQueue();

    final imported = await StickyNotesRepository(storageService: otherStorage)
        .loadAll();
    expect(imported.single.id, 'n1');
    expect(imported.single.attachments.single.id, 'att_1');
    final otherStore = NoteAttachmentStore(storageService: otherStorage);
    expect(await otherStore.loadBytes('att_1'), Uint8List.fromList([5, 6]));
    await other.dispose();
  });
}