import 'package:flutter/foundation.dart';

import '../data/sticky_notes_config_repository.dart';
import '../data/sync_snapshots.dart';
import '../models/note_category.dart';
import '../models/note_sort_mode.dart';
import '../models/sticky_notes_config.dart';

/// 便签配置状态控制器。
///
/// 管理分类列表与默认排序方式。
/// 所有变更即时持久化到 [StickyNotesConfigRepository] 并通知监听者。
class StickyNotesConfigController extends ChangeNotifier {
  StickyNotesConfigController(this._repository);

  final StickyNotesConfigRepository _repository;

  StickyNotesConfig _config = const StickyNotesConfig();
  bool _loaded = false;

  /// 当前配置。
  StickyNotesConfig get config => _config;

  /// 是否已从存储加载。
  bool get loaded => _loaded;

  /// 加载配置（首次调用会写入默认配置）。
  Future<void> load() async {
    _config = await _repository.load();
    _loaded = true;
    latestConfigSnapshot = _config;
    notifyListeners();
  }

  Future<void> _persist(StickyNotesConfig next) async {
    _config = next;
    latestConfigSnapshot = next;
    await _repository.save(next);
    notifyListeners();
  }

  /// 用外部配置整体替换（同步导入用，spec §5）。
  Future<void> replaceConfig(StickyNotesConfig config) => _persist(config);

  /// 新增自定义分类（id 使用 `category_` 前缀，spec §2.3）。
  Future<void> addCategory(String name, {required int colorValue}) async {
    final categories = _config.categories.toList();
    final id = 'category_${DateTime.now().microsecondsSinceEpoch}';
    categories.add(
      NoteCategory(
        id: id,
        name: name,
        colorValue: colorValue,
        displayOrder: categories.length,
      ),
    );
    await _persist(_config.copyWith(categories: categories));
  }

  /// 更新分类（按 id 匹配）。
  Future<void> updateCategory(NoteCategory category) async {
    final categories = _config.categories
        .map((c) => c.id == category.id ? category : c)
        .toList();
    await _persist(_config.copyWith(categories: categories));
  }

  /// 删除分类（该分类下便签由列表侧置为无分类，spec §4.2）。
  Future<void> deleteCategory(String id) async {
    final categories = _config.categories.where((c) => c.id != id).toList();
    await _persist(_config.copyWith(categories: categories));
  }

  /// 重排分类（配合 ReorderableListView.onReorder，newIndex 已调整）。
  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    final categories = _config.categories.toList();
    final moved = categories.removeAt(oldIndex);
    categories.insert(newIndex, moved);
    final reordered = [
      for (var i = 0; i < categories.length; i++)
        categories[i].copyWith(displayOrder: i),
    ];
    await _persist(_config.copyWith(categories: reordered));
  }

  /// 设置默认排序方式。
  Future<void> setDefaultSortMode(NoteSortMode mode) async =>
      _persist(_config.copyWith(defaultSortMode: mode));

  /// 重置为默认配置。
  Future<void> reset() async {
    _config = await _repository.reset();
    latestConfigSnapshot = _config;
    notifyListeners();
  }
}
