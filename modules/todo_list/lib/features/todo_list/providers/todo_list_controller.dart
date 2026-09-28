// ignore_for_file: prefer_initializing_formals
//
// 命名参数（repository 等）需保持公开名以便跨文件（providers/）调用，
// 而字段为私有（_repository），故无法使用 initializing formal。

import 'package:flutter/foundation.dart';

import '../data/todo_list_repository.dart';
import '../models/todo_item.dart';
import '../providers/todo_config_controller.dart';
import '../services/todo_recurrence_resolver.dart';
import '../services/todo_reminder_service.dart';

/// 待办列表状态控制器。
///
/// 管理待办项列表的增删改、完成切换、循环实例补齐与提醒重调度。
/// 所有变更即时持久化到 [TodoListRepository] 并通知监听者。
///
/// 循环实例约定（spec §4.4）：
/// - 模板：`isRecurring`（含 `recurrenceRules`），始终存在、不完成不归档；
/// - 实例：由模板生成，独立 `TodoItem`（`recurrenceRules` 为空），
///   带具体 `dueDate`，id = `<模板id>_<yyyyMMdd>`；
/// - 实例完成后归档，不影响模板规则。
class TodoListController extends ChangeNotifier {
  TodoListController({
    required TodoListRepository repository,
    required TodoRecurrenceResolver resolver,
    required TodoReminderService reminderService,
    required TodoConfigController configController,
  })  : _repository = repository,
        _resolver = resolver,
        _reminderService = reminderService,
        _configController = configController;

  final TodoListRepository _repository;
  final TodoRecurrenceResolver _resolver;
  final TodoReminderService _reminderService;
  final TodoConfigController _configController;

  List<TodoItem> _items = [];
  bool _loaded = false;

  /// 全部待办项（含模板、实例、历史）。
  List<TodoItem> get items => List.unmodifiable(_items);

  /// 在运转的待办（未归档且未完成）：一次性事项 + 循环模板。
  ///
  /// 排除每日自动生成的循环实例（仅完成单日、事项仍在循环）。
  List<TodoItem> get activeItems {
    final templateIds = _items.where((e) => e.isRecurring).map((e) => e.id).toSet();
    return _items
        .where((e) =>
            !e.isArchived && !e.isCompleted && !_isOccurrence(e, templateIds))
        .toList();
  }

  /// 待办历史（已完成）：一次性事项完成 + 循环模板整系列关闭。
  ///
  /// 循环单日完成、模板仍在循环的实例（id 以模板 id 为前缀）不记录。
  List<TodoItem> get historyItems {
    final templateIds = _items.where((e) => e.isRecurring).map((e) => e.id).toSet();
    return _items
        .where((e) => e.isCompleted && !_isOccurrence(e, templateIds))
        .toList();
  }

  /// 是否某个循环模板的单日实例。
  static bool _isOccurrence(TodoItem item, Set<String> templateIds) {
    for (final tid in templateIds) {
      if (item.id.startsWith('${tid}_')) return true;
    }
    return false;
  }

  /// 是否已从存储加载。
  bool get loaded => _loaded;

  /// 加载待办列表并补齐循环实例。
  ///
  /// 幂等：已加载或内存中已有数据（如并发新增）时不覆盖内存数据，
  /// 避免异步加载晚于写入完成时丢失用户操作。
  Future<void> load() async {
    if (_loaded) return;
    final stored = await _repository.loadAll();
    if (_items.isEmpty) {
      _items = stored;
    }
    await _ensureInstances();
    _loaded = true;
    notifyListeners();
  }

  /// 新增待办项；若为循环模板则同步补齐其实例。
  Future<void> add(TodoItem item) async {
    _items = [..._items, item];
    if (item.isRecurring) await _ensureInstancesFor(item);
    await _persistAndReschedule();
  }

  /// 更新待办项（按 id 匹配）；若为循环模板则重新补齐实例。
  Future<void> update(TodoItem item) async {
    _items = [
      for (final e in _items) e.id == item.id ? item : e,
    ];
    if (item.isRecurring) await _ensureInstancesFor(item);
    await _persistAndReschedule();
  }

  /// 删除待办项；若为循环模板则连同其实例一并删除。
  Future<void> delete(String id) async {
    _items = _items
        .where((e) => e.id != id && !e.id.startsWith('${id}_'))
        .toList();
    await _persistAndReschedule();
  }

  /// 切换完成状态。
  ///
  /// 一次性：完成/取消完成并对应归档/移出历史。
  /// 循环模板：不允许整系列完成，改为完成「今天」的当次实例（避免误关整个循环）。
  Future<void> toggleComplete(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final item = _items[index];
    if (item.isRecurring) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await completeOccurrence(item, today);
      return;
    }
    final now = DateTime.now();
    final updated = item.isCompleted
        ? item.copyWith(isCompleted: false, completedAt: null, isArchived: false)
        : item.copyWith(
            isCompleted: true,
            completedAt: now,
          );
    _items = [..._items]..[index] = updated;
    await _persistAndReschedule();
  }

  /// 完成指定日期的当次事项（销项）。
  ///
  /// 完成项保留在列表中，标记完成并排至列表底部；历史按"已完成"体现。
  ///
  /// - 一次性：完成该事项本身；
  /// - 循环模板：仅完成该日期的实例，模板保持开启，循环继续。
  Future<void> completeOccurrence(TodoItem item, DateTime day) async {
    final now = DateTime.now();
    if (item.isRecurring) {
      final day0 = DateTime(day.year, day.month, day.day);
      final instanceId = '${item.id}_${_ymd(day0)}';
      var index = _items.indexWhere((e) => e.id == instanceId);
      if (index < 0) {
        _items = [..._items, _makeInstance(item, day0)];
        index = _items.indexWhere((e) => e.id == instanceId);
      }
      _items = [..._items]
        ..[index] = _items[index].copyWith(
          isCompleted: true,
          completedAt: now,
        );
    } else {
      _items = [
        for (final e in _items)
          e.id == item.id
              ? e.copyWith(
                  isCompleted: true,
                  completedAt: now,
                )
              : e,
      ];
    }
    await _persistAndReschedule();
  }

  /// 关闭循环待办（整系列销项）：标记模板及其全部实例完成。
  Future<void> closeRecurring(String templateId) async {
    final now = DateTime.now();
    _items = [
      for (final e in _items)
        if (e.id == templateId || e.id.startsWith('${templateId}_'))
          e.copyWith(
            isCompleted: true,
            completedAt: now,
          )
        else
          e,
    ];
    await _persistAndReschedule();
  }

  /// 导入合并其他数据（按 id 合并，`updatedAt` 较新者为准）。
  Future<void> import(List<TodoItem> remote) async {
    final merged = <String, TodoItem>{};
    for (final e in _items) {
      merged[e.id] = e;
    }
    for (final e in remote) {
      final local = merged[e.id];
      if (local == null || e.updatedAt.isAfter(local.updatedAt)) {
        merged[e.id] = e;
      }
    }
    _items = merged.values.toList();
    await _ensureInstances();
    await _persistAndReschedule();
  }

  // ── 循环实例补齐 ──

  /// 为所有循环模板补齐缺失实例（从模板创建日到今天）。
  Future<void> _ensureInstances() async {
    for (final template in _items.where((e) => e.isRecurring)) {
      await _ensureInstancesFor(template);
    }
  }

  /// 为单个模板补齐缺失实例。
  Future<void> _ensureInstancesFor(TodoItem template) async {
    final today = DateTime.now();
    final from = DateTime(template.createdAt.year, template.createdAt.month,
        template.createdAt.day);
    final to = DateTime(today.year, today.month, today.day);
    if (from.isAfter(to)) return;

    final dates = _resolver.resolve(template, from, to);
    final additions = <TodoItem>[];
    for (final date in dates) {
      final instanceId = '${template.id}_${_ymd(date)}';
      final exists = _items.any((e) => e.id == instanceId);
      if (exists) continue;
      additions.add(_makeInstance(template, date));
    }
    if (additions.isNotEmpty) {
      _items = [..._items, ...additions];
    }
  }

  /// 生成模板在某日期的循环实例（独立待办项，id = `<模板id>_<yyyyMMdd>`）。
  TodoItem _makeInstance(TodoItem template, DateTime date) => template.copyWith(
        id: '${template.id}_${_ymd(date)}',
        dueDate: date,
        recurrenceRules: const [],
        isCompleted: false,
        completedAt: null,
        isArchived: false,
        createdAt: date,
        updatedAt: DateTime.now(),
      );

  // ── 持久化与提醒重调度 ──

  Future<void> _persistAndReschedule() async {
    await _repository.saveAll(_items);
    if (_configController.loaded) {
      await _reminderService.scheduleAll(
        _items,
        _configController.config,
        DateTime.now(),
      );
    }
    notifyListeners();
  }

  static String _ymd(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';
}