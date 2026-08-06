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
  /// [groupCount] 为班组数量，[slotNames] 为状态名称列表，[cycleCount] 为循环数。
  /// 程序会自动生成班组、状态以及默认的循环偏移分配矩阵。
  Future<void> addRotation({
    required String name,
    required int groupCount,
    required List<String> slotNames,
    required int cycleCount,
    DateTime? baseDate,
    bool isPrimary = false,
  }) async {
    final rotation = _buildRotation(
      name: name.trim(),
      groupCount: groupCount,
      slotNames: slotNames,
      cycleCount: cycleCount,
      baseDate: dateOnly(baseDate ?? DateTime.now()),
    );

    final updatedRotations = [..._config.rotations, rotation];
    await updateConfig(_config.copyWith(rotations: updatedRotations));

    if (isPrimary) {
      await setPrimaryRotation(rotation.id);
    }
  }

  /// 基于模板新增一个轮班。
  ///
  /// [templateId] 使用 [ShiftRotationTemplate] 的 ID；[name] 为轮班自定义名称。
  Future<void> addRotationFromTemplate({
    required String templateId,
    required String name,
    DateTime? baseDate,
    bool isPrimary = false,
  }) async {
    final template = ShiftRotationTemplate.findById(templateId);
    if (template == null) {
      throw ArgumentError('Unknown rotation template: $templateId');
    }

    await addRotation(
      name: name.trim(),
      groupCount: template.groupCount,
      slotNames: template.slotNames,
      cycleCount: template.cycleCount,
      baseDate: baseDate,
      isPrimary: isPrimary,
    );
  }

  /// 生成唯一 ID。
  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return '${prefix}_${timestamp}_$random';
  }

  /// 默认班组颜色色板，按班组数量循环使用。
  int _defaultGroupColor(int index) {
    const colors = [
      0xFF_90A4AE,
      0xFF_7986CB,
      0xFF_4DB6AC,
      0xFF_FFC107,
      0xFF_FF7043,
      0xFF_BA68C8,
    ];
    return colors[index % colors.length];
  }

  /// 构建一个轮班，包含默认班组、状态和分配矩阵。
  ShiftRotation _buildRotation({
    required String name,
    required int groupCount,
    required List<String> slotNames,
    required int cycleCount,
    required DateTime baseDate,
  }) {
    final groups = List.generate(
      groupCount,
      (i) => ShiftGroup(
        id: _generateId('group'),
        name: '${i + 1}班',
        colorValue: _defaultGroupColor(i),
      ),
    );

    final slots = slotNames
        .map((name) => ShiftSlot(name: name))
        .toList();

    final assignments = _buildDefaultAssignments(
      groupCount: groupCount,
      slotCount: slots.length,
      cycleCount: cycleCount,
    );

    return ShiftRotation(
      id: _generateId('rotation'),
      name: name,
      baseDate: baseDate,
      cycleCount: cycleCount,
      groups: groups,
      slots: slots,
      assignments: assignments,
    );
  }

  /// 生成默认的周期分配矩阵。
  ///
  /// 每个班组在周期内的状态按 slot 下标循环偏移，保证每天各班组状态分布均匀。
  List<List<int>> _buildDefaultAssignments({
    required int groupCount,
    required int slotCount,
    required int cycleCount,
  }) {
    final cycleDays = groupCount * cycleCount;
    return List.generate(groupCount, (groupIndex) {
      return List.generate(cycleDays, (dayIndex) {
        return (groupIndex + dayIndex) % slotCount;
      });
    });
  }
}

/// 轮班模板，用于快速创建常见倒班形式。
class ShiftRotationTemplate {
  const ShiftRotationTemplate({
    required this.id,
    required this.displayName,
    required this.groupCount,
    required this.slotNames,
    required this.cycleCount,
  });

  final String id;
  final String displayName;
  final int groupCount;
  final List<String> slotNames;
  final int cycleCount;

  static const List<ShiftRotationTemplate> all = [
    _fourTwoSingle,
    _threeTwoSingle,
    _fourThreeDouble,
    _fiveThreeSingle,
    _sixThreeSingle,
  ];

  static ShiftRotationTemplate? findById(String id) {
    for (final template in all) {
      if (template.id == id) return template;
    }
    return null;
  }

  static const _fourTwoSingle = ShiftRotationTemplate(
    id: 'template_4_2_single',
    displayName: '四班两倒单循环',
    groupCount: 4,
    slotNames: ['白班', '上夜班', '下夜班', '休息'],
    cycleCount: 1,
  );

  static const _threeTwoSingle = ShiftRotationTemplate(
    id: 'template_3_2_single',
    displayName: '三班两倒单循环',
    groupCount: 3,
    slotNames: ['白班', '夜班', '休息'],
    cycleCount: 1,
  );

  static const _fourThreeDouble = ShiftRotationTemplate(
    id: 'template_4_3_double',
    displayName: '四班三倒双循环',
    groupCount: 4,
    slotNames: ['早班', '中班', '晚班', '休息'],
    cycleCount: 2,
  );

  static const _fiveThreeSingle = ShiftRotationTemplate(
    id: 'template_5_3_single',
    displayName: '五班三倒单循环',
    groupCount: 5,
    slotNames: ['早班', '中班', '晚班', '休息', '休息'],
    cycleCount: 1,
  );

  static const _sixThreeSingle = ShiftRotationTemplate(
    id: 'template_6_3_single',
    displayName: '六班三倒单循环',
    groupCount: 6,
    slotNames: ['早班', '中班', '晚班', '休息', '休息', '休息'],
    cycleCount: 1,
  );
}
