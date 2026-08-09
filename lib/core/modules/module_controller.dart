// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';

import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_state.dart';
import 'package:ametoolbox/core/modules/module_contract.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

/// 模块管理状态控制器。
///
/// 负责维护模块启用状态、持久化以及与 UI 层的通知联动。
class ModuleController extends ChangeNotifier {
  ModuleController({
    required StorageService storage,
    required List<ModuleContract> registry,
  })  : _storage = storage,
        _registry = registry {
    _initDefaultStates();
  }

  final StorageService _storage;
  final List<ModuleContract> _registry;

  final Map<String, ModuleState> _states = {};

  /// 已注册的全部模块定义（来自 [ModuleRegistry]）。
  List<ModuleDefinition> get definitions =>
      _registry.map((m) => m.definition).toList();

  /// 已注册的全部模块契约实例。
  List<ModuleContract> get registeredModules => List.unmodifiable(_registry);

  /// 当前已启用的模块数量。
  int get enabledCount => _states.values.where((s) => s.enabled).length;

  /// 按 [displayOrder] 排序后的已启用模块。
  List<ModuleContract> get enabledModules {
    final sorted = _registry.toList()
      ..sort((a, b) {
        final orderA = _states[a.definition.id]?.displayOrder ?? 0;
        final orderB = _states[b.definition.id]?.displayOrder ?? 0;
        return orderA.compareTo(orderB);
      });
    return sorted.where((m) => isEnabled(m.definition.id)).toList();
  }

  /// 横屏/双列布局下按 [displayOrderLandscape] 排序后的已启用模块。
  ///
  /// 未单独设置横屏顺序的模块回退到竖屏 [displayOrder]，保证首次切换横屏时
  /// 顺序与竖屏一致。
  List<ModuleContract> get enabledModulesLandscape {
    final sorted = _registry.toList()
      ..sort((a, b) {
        final orderA = _landscapeOrder(a.definition.id);
        final orderB = _landscapeOrder(b.definition.id);
        return orderA.compareTo(orderB);
      });
    return sorted.where((m) => isEnabled(m.definition.id)).toList();
  }

  int _landscapeOrder(String moduleId) {
    return _states[moduleId]?.displayOrderLandscape ??
        _states[moduleId]?.displayOrder ??
        0;
  }

  /// 查询指定模块是否启用。
  bool isEnabled(String moduleId) {
    return _states[moduleId]?.enabled ?? false;
  }

  /// 加载本地持久化的模块状态，并用持久化值覆盖默认状态。
  Future<void> load() async {
    try {
      final storedStates = await _storage.getModuleStates();
      final storedDefs = await _storage.getModuleDefinitions();

      // 以注册表为权威来源，用 storage 中的状态覆盖默认状态。
      for (var i = 0; i < _registry.length; i++) {
        final module = _registry[i];
        final id = module.definition.id;

        final storedState = storedStates.cast<ModuleState?>().firstWhere(
              (s) => s?.moduleId == id,
              orElse: () => null,
            );

        if (storedState != null) {
          _states[id] = storedState;
        }
      }

      // 持久化合并后的完整定义与状态，确保首次启动写入默认值。
      await _saveDefinitions(storedDefs);
      await _saveStates();

      notifyListeners();
    } catch (_) {
      // 存储未就绪时保持默认状态。
      notifyListeners();
    }
  }

  /// 切换指定模块的启用状态。
  ///
  /// 启用模块时，将其显示顺序设置为当前最大值 +1，使其默认排在最后。
  Future<void> toggleModule(String moduleId) async {
    final state = _states[moduleId];
    if (state == null) return;

    state.enabled = !state.enabled;

    if (state.enabled) {
      final maxOrder = _states.values
          .where((s) => s.enabled && s.moduleId != moduleId)
          .map((s) => s.displayOrder)
          .fold(-1, (max, order) => order > max ? order : max);
      state.displayOrder = maxOrder + 1;
    }

    await _saveStates();
    notifyListeners();
  }

  /// 设置指定模块的显示顺序。
  Future<void> setDisplayOrder(String moduleId, int order) async {
    final state = _states[moduleId];
    if (state == null || state.displayOrder == order) return;

    state.displayOrder = order;
    await _saveStates();
    notifyListeners();
  }

  /// 按已启用模块列表中的索引重新排序。
  ///
  /// [oldIndex] 为拖拽起始索引，[newIndex] 为模块最终应处的目标位置索引。
  Future<void> reorderEnabledModules(int oldIndex, int newIndex) async {
    final enabled = enabledModules.toList();
    if (oldIndex < 0 || oldIndex >= enabled.length) return;
    if (newIndex < 0 || newIndex > enabled.length) return;
    if (oldIndex == newIndex) return;

    final moved = enabled.removeAt(oldIndex);
    enabled.insert(newIndex, moved);

    for (var i = 0; i < enabled.length; i++) {
      final state = _states[enabled[i].definition.id];
      if (state != null) {
        state.displayOrder = i;
      }
    }

    await _saveStates();
    notifyListeners();
  }

  /// 按已启用模块列表中的索引重新排序（横屏/双列布局）。
  ///
  /// 仅更新各模块的 [ModuleState.displayOrderLandscape]，不影响竖屏顺序。
  /// [oldIndex] 为拖拽起始索引，[newIndex] 为模块最终应处的目标位置索引。
  Future<void> reorderEnabledModulesLandscape(
    int oldIndex,
    int newIndex,
  ) async {
    final enabled = enabledModulesLandscape.toList();
    if (oldIndex < 0 || oldIndex >= enabled.length) return;
    if (newIndex < 0 || newIndex > enabled.length) return;
    if (oldIndex == newIndex) return;

    final moved = enabled.removeAt(oldIndex);
    enabled.insert(newIndex, moved);

    for (var i = 0; i < enabled.length; i++) {
      final state = _states[enabled[i].definition.id];
      if (state != null) {
        state.displayOrderLandscape = i;
      }
    }

    await _saveStates();
    notifyListeners();
  }

  void _initDefaultStates() {
    for (var i = 0; i < _registry.length; i++) {
      final module = _registry[i];
      _states[module.definition.id] = ModuleState(
        moduleId: module.definition.id,
        enabled: module.definition.defaultEnabled,
        displayOrder: i,
      );
    }
  }

  Future<void> _saveDefinitions(List<ModuleDefinition> currentStored) async {
    // 仅当 storage 中尚无定义时才写入，避免覆盖后续可能由用户或模块自身更新的元数据。
    if (currentStored.isEmpty) {
      await _storage.setModuleDefinitions(definitions);
    }
  }

  Future<void> _saveStates() async {
    await _storage.setModuleStates(_states.values.toList());
  }
}
