import 'dart:convert';
import 'dart:typed_data';

import 'package:ametoolbox/core/storage/storage_service.dart';

/// 附件 id → 字节 的**模块级共享注册表**（写穿缓存）。
///
/// 由 [NoteAttachmentStore] 在保存 / 读取 / 删除字节时同步维护；
/// 模块 `initialize` 会预载全部现存附件字节，使 `exportData`（同步签名）
/// 无需异步 IO 即可拿到最新字节。
final Map<String, Uint8List> attachmentBytesCache = <String, Uint8List>{};

/// 便签附件字节存储。
///
/// 每个附件字节以 base64 字符串单独存于 `module_sticky_notes_attachments_<id>`，
/// 读取/删除均按附件 id 精准操作，避免把全部大文件一次性载入内存。
/// 与 `StickyNotesRepository`（便签列表）分层：便签只持有附件元数据。
class NoteAttachmentStore {
  NoteAttachmentStore({required StorageService storageService})
      : _storage = storageService;

  static const keyPrefix = 'module_sticky_notes_attachments_';

  final StorageService _storage;

  String _key(String id) => '$keyPrefix$id';

  /// 读取指定附件的字节；不存在返回 null。命中后写入内存缓存。
  Future<Uint8List?> loadBytes(String id) async {
    final cached = attachmentBytesCache[id];
    if (cached != null) return cached;
    final data = await _storage.loadData(_key(id));
    final b64 = data?['data'] as String?;
    if (b64 == null) return null;
    final bytes = base64Decode(b64);
    attachmentBytesCache[id] = bytes;
    return bytes;
  }

  /// 保存指定附件的字节（同步写入内存缓存）。
  Future<void> saveBytes(String id, Uint8List bytes) async {
    await _storage.saveData(_key(id), {'data': base64Encode(bytes)});
    attachmentBytesCache[id] = bytes;
  }

  /// 删除指定附件的字节并清理内存缓存。
  Future<void> deleteBytes(String id) async {
    await _storage.deleteData(_key(id));
    attachmentBytesCache.remove(id);
  }

  /// 预载指定附件 id 的字节到内存缓存（便签删除级联、同步导出前调用）。
  ///
  /// 已缓存的 id 跳过；存储中不存在的 id 静默忽略（可能已被清理）。
  Future<void> preload(Iterable<String> ids) async {
    for (final id in ids) {
      if (attachmentBytesCache.containsKey(id)) continue;
      await loadBytes(id);
    }
  }
}