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

  /// 记录最近查看的轮班，作为日历下次默认显示的轮班。
  Future<void> setLastViewedRotation(String rotationId) async {
    if (_config.lastViewedRotationId == rotationId) return;
    await updateConfig(_config.copyWith(lastViewedRotationId: rotationId));
  }

  /// 设置我的班组（可选）。[rotationId] 与 [groupId] 同时为空时等价于清除。
  Future<void> setMyTeam(String? rotationId, String? groupId) async {
    if (rotationId == null || groupId == null) {
      if (!_hasMyTeam) return;
      await updateConfig(_config.copyWith(clearMyTeam: true));
      return;
    }
    if (_config.myTeamRotationId == rotationId &&
        _config.myTeamGroupId == groupId) {
      return;
    }
    await updateConfig(
      _config.copyWith(myTeamRotationId: rotationId, myTeamGroupId: groupId),
    );
  }

  /// 清除我的班组设置。
  Future<void> clearMyTeam() async {
    if (!_hasMyTeam) return;
    await updateConfig(_config.copyWith(clearMyTeam: true));
  }

  bool get _hasMyTeam =>
      _config.myTeamRotationId != null || _config.myTeamGroupId != null;

  /// 删除指定轮班。
  Future<void> deleteRotation(String rotationId) async {
    final updatedRotations =
        _config.rotations.where((r) => r.id != rotationId).toList();

    final clearLastViewed = _config.lastViewedRotationId == rotationId;
    final clearMyTeam = _config.myTeamRotationId == rotationId;

    await updateConfig(
      _config.copyWith(
        rotations: updatedRotations,
        clearLastViewedRotationId: clearLastViewed,
        clearMyTeam: clearMyTeam,
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
  }

  /// 生成唯一 ID。
  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return '${prefix}_${timestamp}_$random';
  }
}
