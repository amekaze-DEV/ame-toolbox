// ignore_for_file: prefer_initializing_formals
//
// 命名参数（repository 等）需保持公开名以便跨文件（providers/）调用，
// 而字段为私有（_repository），故无法使用 initializing formal。

import 'package:flutter/foundation.dart';

import '../data/sticky_notes_repository.dart';
import '../models/sticky_note.dart';

/// 便签列表状态控制器。
///
/// 管理便签的增删改、置顶切换、分类置空与导入合并，
/// 并持有主页面分类筛选状态。
/// 所有变更即时持久化到 [StickyNotesRepository] 并通知监听者。
class StickyNotesController extends ChangeNotifier {
  StickyNotesController({required StickyNotesRepository repository})
      : _repository = repository;

  final StickyNotesRepository _repository;

  List<StickyNote> _notes = [];
  bool _loaded = false;
  String? _categoryFilter;

  /// 全部便签。
  List<StickyNote> get notes => List.unmodifiable(_notes);

  /// 是否已从存储加载。
  bool get loaded => _loaded;

  /// 当前分类筛选（null 表示不限）。
  String? get categoryFilter => _categoryFilter;

  /// 加载便签列表。
  ///
  /// 幂等：已加载或内存中已有数据（如并发新增）时不覆盖内存数据，
  /// 避免异步加载晚于写入完成时丢失用户操作。
  Future<void> load() async {
    if (_loaded) return;
    final stored = await _repository.loadAll();
    if (_notes.isEmpty) {
      _notes = stored;
    }
    _loaded = true;
    notifyListeners();
  }

  /// 新增便签。
  Future<void> add(StickyNote note) async {
    _notes = [..._notes, note];
    await _persist();
  }

  /// 更新便签（按 id 匹配）。
  Future<void> update(StickyNote note) async {
    _notes = [
      for (final e in _notes) e.id == note.id ? note : e,
    ];
    await _persist();
  }

  /// 删除便签。
  Future<void> delete(String id) async {
    _notes = _notes.where((e) => e.id != id).toList();
    await _persist();
  }

  /// 切换置顶状态（置顶记录时间，取消置顶清空时间）。
  Future<void> togglePin(String id) async {
    final index = _notes.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final note = _notes[index];
    final updated = note.isPinned
        ? note.copyWith(isPinned: false, clearPinnedAt: true)
        : note.copyWith(isPinned: true, pinnedAt: DateTime.now());
    _notes = [..._notes]..[index] = updated;
    await _persist();
  }

  /// 将指定分类下的便签置为无分类（删除分类后调用，spec §4.2）。
  Future<void> clearCategory(String categoryId) async {
    _notes = [
      for (final e in _notes)
        e.categoryId == categoryId ? e.copyWith(clearCategoryId: true) : e,
    ];
    await _persist();
  }

  /// 导入合并其他数据（按 id 合并，`updatedAt` 较新者为准）。
  Future<void> import(List<StickyNote> remote) async {
    final merged = <String, StickyNote>{};
    for (final e in _notes) {
      merged[e.id] = e;
    }
    for (final e in remote) {
      final local = merged[e.id];
      if (local == null || e.updatedAt.isAfter(local.updatedAt)) {
        merged[e.id] = e;
      }
    }
    _notes = merged.values.toList();
    await _persist();
  }

  /// 设置分类筛选（null 表示不限）。
  void setCategoryFilter(String? categoryId) {
    _categoryFilter = categoryId;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _repository.saveAll(_notes);
    notifyListeners();
  }
}
