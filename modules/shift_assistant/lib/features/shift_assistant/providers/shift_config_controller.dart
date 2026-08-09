import 'dart:math';

import 'package:flutter/material.dart';

import '../data/shift_config_repository.dart';
import '../models/shift_config.dart';
import '../utils/date_utils.dart';

/// 倒班助手配置控制器。
class ShiftConfigController extends ChangeNotifier {
  ShiftConfigController({required this._repository});

  final ShiftConfigRepository _repository;

  ShiftConfig _config = ShiftConfig.defaults();

  ShiftConfig get config => _config;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _config = await _repository.load();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateConfig(ShiftConfig config) async {
    _config = config;
    await _repository.save(config);
    notifyListeners();
  }

  /// 将 [rotationId] 设为主要轮班，并取消其他轮班的主要状态。
  Future<void> setPrimaryRotation(String rotationId) async {
    if (_config.primaryRotationId == rotationId &&
        _config.rotations.every((r) => r.isPrimary == (r.id == rotationId))) {
      return;
    }

    final updatedRotations = _config.rotations
        .map((r) => r.copyWith(isPrimary: r.id == rotationId))
        .toList();

    await updateConfig(
      _config.copyWith(
        rotations: updatedRotations,
        primaryRotationId: rotationId,
      ),
    );
  }

  /// 取消主要轮班设置。
  Future<void> clearPrimaryRotation() async {
    if (_config.primaryRotationId == null &&
        _config.rotations.every((r) => !r.isPrimary)) {
      return;
    }

    final updatedRotations = _config.rotations
        .map((r) => r.copyWith(isPrimary: false))
        .toList();

    await updateConfig(
      _config.copyWith(
        rotations: updatedRotations,
        clearPrimaryRotationId: true,
      ),
    );
  }

  /// 删除指定轮班。
  Future<void> deleteRotation(String rotationId) async {
    final wasPrimary = _config.primaryRotationId == rotationId;
    final updatedRotations =
        _config.rotations.where((r) => r.id != rotationId).toList();

    await updateConfig(
      _config.copyWith(
        rotations: updatedRotations,
        clearPrimaryRotationId: wasPrimary,
      ),
    );
  }

  /// 更新单个轮班。
  Future<void> updateRotation(ShiftRotation rotation) async {
    final updatedRotations = _config.rotations
        .map((r) => r.id == rotation.id ? rotation : r)
        .toList();

    await updateConfig(_config.copyWith(rotations: updatedRotations));
  }

  /// 新增一个轮班。
  ///
  /// 接收用户在添加对话框中完整配置的轮班信息（班组、状态、周期安排矩阵），
  /// 与旧实现由模板自动生成班组/状态不同，这里完全由用户手动设置。
  ///
  /// - [name] 轮班名称
  /// - [baseDate] 轮班起始日期，设定后向前后推算班次
  /// - [cycleDays] 循环周期天数，范围 1~30
  /// - [groups] 班组列表（1~8 个）
  /// - [slots] 轮班状态列表
  /// - [assignments] 周期安排矩阵（行=班组，列=周期内第几天）
  Future<void> addRotation({
    required String name,
    required DateTime baseDate,
    required int cycleDays,
    required List<ShiftGroup> groups,
    required List<ShiftSlot> slots,
    required List<List<int>> assignments,
    bool isPrimary = false,
  }) async {
    final rotation = ShiftRotation(
      id: _generateId('rotation'),
      name: name.trim(),
      baseDate: dateOnly(baseDate),
      cycleDays: cycleDays,
      groups: groups,
      slots: slots,
      assignments: assignments,
    );

    final updatedRotations = [..._config.rotations, rotation];
    await updateConfig(_config.copyWith(rotations: updatedRotations));

    if (isPrimary) {
      await setPrimaryRotation(rotation.id);
    }
  }

  /// 生成唯一 ID。
  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return '${prefix}_${timestamp}_$random';
  }
}
