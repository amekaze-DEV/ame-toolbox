import 'package:ametoolbox/core/providers/file_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/note_attachment_store.dart';
import '../services/attachment_service.dart';

/// 注入附件字节存储。
final noteAttachmentStoreProvider = Provider<NoteAttachmentStore>((ref) {
  return NoteAttachmentStore(storageService: ref.watch(storageServiceProvider));
});

/// 注入附件编排服务（选择 / 打开 / 下载 / 删除）。
final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  return AttachmentService(
    attachmentStore: ref.watch(noteAttachmentStoreProvider),
    filePicker: ref.watch(filePickerProvider),
    fileLauncher: ref.watch(fileLauncherProvider),
  );
});