import 'package:ametoolbox/core/storage/storage_service.dart';

import '../models/sticky_note.dart';

/// 便签列表持久化 Repository。
///
/// 通过 [StorageService] 的通用键值接口整体存取，存储 key 为
/// `module_sticky_notes_notes`，以 JSON 列表形式序列化。
class StickyNotesRepository {
  StickyNotesRepository({required StorageService storageService})
      : _storage = storageService;

  static const _notesKey = 'module_sticky_notes_notes';

  final StorageService _storage;

  static const _schemaVersion = 1;

  /// 加载所有便签，首次使用返回空列表。
  Future<List<StickyNote>> loadAll() async {
    final json = await _storage.loadData(_notesKey);
    if (json == null) return <StickyNote>[];
    final schemaVersion = json['schemaVersion'] as int? ?? 1;
    assert(schemaVersion == 1,
        'Unsupported StickyNote list schema version: $schemaVersion');
    final notes = json['notes'] as List<dynamic>?;
    if (notes == null) return <StickyNote>[];
    return notes
        .map((e) => StickyNote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 整体保存所有便签。
  Future<void> saveAll(List<StickyNote> notes) async {
    await _storage.saveData(_notesKey, {
      'schemaVersion': _schemaVersion,
      'notes': notes.map((e) => e.toJson()).toList(),
    });
  }

  /// 追加或替换单个便签（按 id 匹配）。
  Future<void> upsert(StickyNote note) async {
    final notes = await loadAll();
    final index = notes.indexWhere((e) => e.id == note.id);
    if (index >= 0) {
      notes[index] = note;
    } else {
      notes.add(note);
    }
    await saveAll(notes);
  }

  /// 按 id 删除单个便签。
  Future<void> delete(String id) async {
    final notes = await loadAll();
    notes.removeWhere((e) => e.id == id);
    await saveAll(notes);
  }

  /// 清空所有便签。
  Future<void> clearAll() async {
    await _storage.deleteData(_notesKey);
  }
}
