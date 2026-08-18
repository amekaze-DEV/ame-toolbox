import 'package:flutter/foundation.dart';

import '../data/todo_config_repository.dart';
import '../models/holiday_info.dart';
import '../models/todo_category.dart';
import '../models/todo_config.dart';

/// 配置状态控制器。
///
/// 管理分类列表、提醒开关、默认提醒分钟数、日常置顶配置。
/// 所有变更即时持久化到 [TodoConfigRepository] 并通知监听者。
class TodoConfigController extends ChangeNotifier {
  TodoConfigController(this._repository);

  final TodoConfigRepository _repository;

  TodoConfig _config = const TodoConfig();
  bool _loaded = false;

  /// 当前配置。
  TodoConfig get config => _config;

  /// 是否已从存储加载。
  bool get loaded => _loaded;

  /// 加载配置（首次调用会写入默认配置）。
  Future<void> load() async {
    _config = await _repository.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist(TodoConfig next) async {
    _config = next;
    await _repository.save(next);
    notifyListeners();
  }

  /// 设置提醒总开关。
  Future<void> setRemindEnabled(bool value) =>
      _persist(_config.copyWith(remindEnabled: value));

  /// 设置默认提前提醒分钟数。
  Future<void> setDefaultRemindMinutes(int value) =>
      _persist(_config.copyWith(defaultRemindMinutes: value));

  /// 设置日常事项是否置顶。
  Future<void> setDailyTop(bool value) =>
      _persist(_config.copyWith(dailyTop: value));

  /// 更新节假日缓存（key 为 yyyy-MM-dd）与最后更新时间。
  Future<void> updateHolidayCache(
    Map<String, HolidayInfo> cache,
    DateTime lastUpdated,
  ) =>
      _persist(
        _config.copyWith(
          holidayCache: cache,
          holidaysLastUpdated: lastUpdated,
        ),
      );

  /// 新增分类。
  Future<void> addCategory(String name, {required int colorValue}) async {
    final categories = _config.categories.toList();
    final id = 'category_${DateTime.now().microsecondsSinceEpoch}';
    categories.add(
      TodoCategory(
        id: id,
        name: name,
        colorValue: colorValue,
        displayOrder: categories.length,
      ),
    );
    await _persist(_config.copyWith(categories: categories));
  }

  /// 更新分类（按 id 匹配）。
  Future<void> updateCategory(TodoCategory category) async {
    final categories = _config.categories
        .map((c) => c.id == category.id ? category : c)
        .toList();
    await _persist(_config.copyWith(categories: categories));
  }

  /// 删除分类（该分类下待办项的分类由列表侧置为 null）。
  Future<void> deleteCategory(String id) async {
    final categories =
        _config.categories.where((c) => c.id != id).toList();
    await _persist(_config.copyWith(categories: categories));
  }

  /// 重排分类（配合 `ReorderableListView.onReorderItem`，newIndex 已调整）。
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

  /// 重置为默认配置。
  Future<void> reset() async {
    _config = await _repository.reset();
    notifyListeners();
  }
}