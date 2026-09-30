import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/data/note_attachment_store.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_attachment.dart';
import 'package:sticky_notes_module/features/sticky_notes/services/attachment_service.dart';

import '../helpers/fake_file_services.dart';
import '../helpers/memory_storage_service.dart';

void main() {
  late MemoryStorageService storage;
  late NoteAttachmentStore store;
  late FakeFilePickerService picker;
  late FakeFileLauncherService launcher;
  late AttachmentService service;
  final createdAt = DateTime(2026, 9, 1, 9);

  setUp(() {
    storage = MemoryStorageService();
    store = NoteAttachmentStore(storageService: storage);
    picker = FakeFilePickerService();
    launcher = FakeFileLauncherService();
    service = AttachmentService(
      attachmentStore: store,
      filePicker: picker,
      fileLauncher: launcher,
    );
    attachmentBytesCache.clear();
  });

  group('AttachmentService', () {
    test('addFromPicker 落库字节并返回元数据', () async {
      picker.pickFileQueue.add(
        fakePickedFile(
          name: '报告.pdf',
          bytes: [1, 2, 3, 4],
          mimeType: 'application/pdf',
        ),
      );

      final attachment = await service.addFromPicker();

      expect(attachment, isNotNull);
      expect(attachment!.fileName, '报告.pdf');
      expect(attachment.sizeBytes, 4);
      expect(attachment.mimeType, 'application/pdf');
      expect(attachment.id, startsWith('att_'));
      expect(
        await store.loadBytes(attachment.id),
        Uint8List.fromList([1, 2, 3, 4]),
      );
      expect(attachmentBytesCache.containsKey(attachment.id), true);
    });

    test('addFromPicker 用户取消返回 null', () async {
      expect(await service.addFromPicker(), isNull);
    });

    test('addFromPicker 系统上报大小超限直接拒绝且不落库', () async {
      picker.pickFileQueue.add(
        fakePickedFile(
          name: 'big.bin',
          bytes: [1],
          declaredSize: AttachmentService.kMaxAttachmentBytes + 1,
        ),
      );

      await expectLater(
        service.addFromPicker(),
        throwsA(isA<AttachmentTooLargeException>()),
      );
      expect(attachmentBytesCache, isEmpty);
    });

    test('addFromPicker 实际字节超限拒绝（上报大小不可信时）', () async {
      picker.pickFileQueue.add(
        fakePickedFile(
          name: 'big.bin',
          bytes: Uint8List(AttachmentService.kMaxAttachmentBytes + 1),
          declaredSize: 1,
        ),
      );

      await expectLater(
        service.addFromPicker(),
        throwsA(isA<AttachmentTooLargeException>()),
      );
      expect(attachmentBytesCache, isEmpty);
    });

    test('open 经系统默认查看器打开', () async {
      picker.pickFileQueue.add(fakePickedFile(name: 'a.txt', bytes: [7, 8]));
      final attachment = (await service.addFromPicker())!;

      await service.open(attachment);

      expect(launcher.openedFileNames, ['a.txt']);
      expect(launcher.openedBytes.single, Uint8List.fromList([7, 8]));
    });

    test('open 字节缺失抛 StateError', () async {
      final missing = NoteAttachment(
        id: 'att_missing',
        fileName: 'x.txt',
        sizeBytes: 0,
        createdAt: createdAt,
      );
      await expectLater(service.open(missing), throwsStateError);
    });

    test('download 返回保存路径', () async {
      picker.pickFileQueue.add(fakePickedFile(name: 'b.txt'));
      final attachment = (await service.addFromPicker())!;
      launcher.savePath = 'D:/out/b.txt';

      expect(await service.download(attachment), 'D:/out/b.txt');
      expect(launcher.savedFileNames, ['b.txt']);
    });

    test('download 用户取消返回 null', () async {
      picker.pickFileQueue.add(fakePickedFile(name: 'b.txt'));
      final attachment = (await service.addFromPicker())!;
      launcher.savePath = null;

      expect(await service.download(attachment), isNull);
    });

    test('delete 清理字节与缓存', () async {
      picker.pickFileQueue.add(fakePickedFile(name: 'c.txt'));
      final attachment = (await service.addFromPicker())!;

      await service.delete(attachment.id);

      expect(await store.loadBytes(attachment.id), isNull);
      expect(attachmentBytesCache.containsKey(attachment.id), false);
    });
  });

  group('NoteAttachmentStore', () {
    test('saveBytes 写穿缓存，loadBytes 命中缓存不再读存储', () async {
      await store.saveBytes('att_x', Uint8List.fromList([9]));
      // 删除存储侧数据后仍可读到 → 说明命中内存缓存。
      await storage.deleteData('${NoteAttachmentStore.keyPrefix}att_x');

      expect(await store.loadBytes('att_x'), Uint8List.fromList([9]));
    });

    test('loadBytes 不存在返回 null', () async {
      expect(await store.loadBytes('att_none'), isNull);
    });

    test('preload 预载已存在附件并忽略缺失 id', () async {
      await store.saveBytes('att_a', Uint8List.fromList([1]));
      await store.saveBytes('att_b', Uint8List.fromList([2]));
      attachmentBytesCache.clear();

      await store.preload(['att_a', 'att_b', 'att_missing']);

      expect(attachmentBytesCache['att_a'], Uint8List.fromList([1]));
      expect(attachmentBytesCache['att_b'], Uint8List.fromList([2]));
      expect(attachmentBytesCache.containsKey('att_missing'), false);
    });
  });
}