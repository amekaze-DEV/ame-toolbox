import 'package:ametoolbox/core/files/file_launcher_service.dart';
import 'package:ametoolbox/core/files/file_picker_service.dart';

import '../data/note_attachment_store.dart';
import '../models/note_attachment.dart';

/// 附件超过大小上限（15MB）。
class AttachmentTooLargeException implements Exception {
  const AttachmentTooLargeException();
  @override
  String toString() => '附件超过 15MB 上限';
}

/// 附件编排服务：选择→校验→入字节存储，以及打开 / 下载 / 删除。
///
/// 字节缓存由 [NoteAttachmentStore]（写穿）维护，本服务不直接触碰缓存。
class AttachmentService {
  AttachmentService({
    required NoteAttachmentStore attachmentStore,
    required FilePickerService filePicker,
    required FileLauncherService fileLauncher,
  })  : _store = attachmentStore,
        _picker = filePicker,
        _launcher = fileLauncher;

  /// 单个附件最大字节数（15MB）。
  static const int kMaxAttachmentBytes = 15 * 1024 * 1024;

  final NoteAttachmentStore _store;
  final FilePickerService _picker;
  final FileLauncherService _launcher;

  /// 从本地选取并落库一个附件，返回其元数据；用户取消返回 null。
  ///
  /// 超过 15MB 抛 [AttachmentTooLargeException]，由调用方提示。
  Future<NoteAttachment?> addFromPicker() async {
    final picked = await _picker.pickFile();
    if (picked == null) return null;

    final declared = picked.sizeBytes;
    if (declared != null && declared > kMaxAttachmentBytes) {
      throw const AttachmentTooLargeException();
    }
    final bytes = await picked.readContent();
    if (bytes.length > kMaxAttachmentBytes) {
      throw const AttachmentTooLargeException();
    }

    final id = 'att_${DateTime.now().microsecondsSinceEpoch}';
    await _store.saveBytes(id, bytes);
    return NoteAttachment(
      id: id,
      fileName: picked.name,
      sizeBytes: bytes.length,
      mimeType: picked.mimeType,
      createdAt: DateTime.now(),
    );
  }

  /// 用系统默认应用打开附件（字节写临时文件后由底座调系统查看器）。
  Future<void> open(NoteAttachment attachment) async {
    final bytes = await _store.loadBytes(attachment.id);
    if (bytes == null) {
      throw StateError('附件不存在或已删除');
    }
    await _launcher.openBytesWithDefaultApp(bytes, attachment.fileName);
  }

  /// 弹出“另存为”对话框下载附件；返回保存路径，取消返回 null。
  Future<String?> download(NoteAttachment attachment) async {
    final bytes = await _store.loadBytes(attachment.id);
    if (bytes == null) {
      throw StateError('附件不存在或已删除');
    }
    return _launcher.saveBytesWithDialog(bytes, attachment.fileName);
  }

  /// 删除附件（删除对应字节存储并清理共享注册表）。
  Future<void> delete(String id) async {
    await _store.deleteBytes(id);
  }
}