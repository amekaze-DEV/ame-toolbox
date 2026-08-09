import 'dart:math';

/// 倒班助手模块配置。
///
/// 保存轮班列表、主要轮班、节假日缓存等。
class ShiftConfig {
  /// 轮班列表。
  final List<ShiftRotation> rotations;

  /// 主要轮班 ID；为 null 时不设置主要轮班。
  final String? primaryRotationId;

  /// 节假日缓存，key 为 yyyy-MM-dd。
  final Map<String, HolidayInfo> holidayCache;

  /// 节假日数据最后更新时间。
  final DateTime? holidaysLastUpdated;

  const ShiftConfig({
    required this.rotations,
    this.primaryRotationId,
    this.holidayCache = const {},
    this.holidaysLastUpdated,
  });

  /// 默认配置：单个四班两倒单循环轮班。
  factory ShiftConfig.defaults() {
    final rotation = ShiftRotation(
      id: 'rotation_default',
      name: '我的轮班',
      baseDate: _defaultBaseDate,
      cycleDays: 4,
      groups: const [
        ShiftGroup(id: 'group_1', name: '一班', colorValue: 0xFF_90A4AE),
        ShiftGroup(id: 'group_2', name: '二班', colorValue: 0xFF_7986CB),
        ShiftGroup(id: 'group_3', name: '三班', colorValue: 0xFF_4DB6AC),
        ShiftGroup(id: 'group_4', name: '四班', colorValue: 0xFF_FFC107),
      ],
      slots: const [
        ShiftSlot(name: '白班', startTime: '08:00', endTime: '20:00'),
        ShiftSlot(name: '上夜班', startTime: '20:00', endTime: '02:00'),
        ShiftSlot(name: '下夜班', startTime: '02:00', endTime: '08:00'),
        ShiftSlot(name: '休息', isRest: true),
      ],
      assignments: const [
        [0, 1, 2, 3],
        [3, 0, 1, 2],
        [2, 3, 0, 1],
        [1, 2, 3, 0],
      ],
      isPrimary: true,
    );

    return ShiftConfig(
      rotations: [rotation],
      primaryRotationId: 'rotation_default',
    );
  }

  static final _defaultBaseDate = DateTime(2026, 8, 1);

  /// 获取按渲染顺序排列的轮班：主要轮班置顶，其余按创建顺序。
  List<ShiftRotation> get orderedRotations {
    final primary = primaryRotationId;
    final primaryRotation =
        primary == null ? null : _findRotationById(primary);

    final others = rotations.where((r) => r.id != primary).toList();

    if (primaryRotation == null) return others;
    return [primaryRotation, ...others];
  }

  /// 根据 ID 查找轮班。
  ShiftRotation? findRotationById(String id) => _findRotationById(id);

  ShiftRotation? _findRotationById(String id) {
    for (final rotation in rotations) {
      if (rotation.id == id) return rotation;
    }
    return null;
  }

  /// 获取主要轮班；未设置时返回第一个轮班（若存在）。
  ShiftRotation? get primaryRotation {
    final id = primaryRotationId;
    if (id != null) return _findRotationById(id);
    return rotations.isEmpty ? null : rotations.first;
  }

  ShiftConfig copyWith({
    List<ShiftRotation>? rotations,
    String? primaryRotationId,
    bool clearPrimaryRotationId = false,
    Map<String, HolidayInfo>? holidayCache,
    DateTime? holidaysLastUpdated,
    bool clearHolidaysLastUpdated = false,
  }) =>
      ShiftConfig(
        rotations: rotations ?? this.rotations,
        primaryRotationId: clearPrimaryRotationId
            ? null
            : (primaryRotationId ?? this.primaryRotationId),
        holidayCache: holidayCache ?? this.holidayCache,
        holidaysLastUpdated: clearHolidaysLastUpdated
            ? null
            : (holidaysLastUpdated ?? this.holidaysLastUpdated),
      );

  Map<String, dynamic> toJson() => {
        'rotations': rotations.map((e) => e.toJson()).toList(),
        'primaryRotationId': primaryRotationId,
        'holidayCache': holidayCache.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        'holidaysLastUpdated': holidaysLastUpdated?.toIso8601String(),
      };

  factory ShiftConfig.fromJson(Map<String, dynamic> json) => ShiftConfig(
        rotations: (json['rotations'] as List<dynamic>?)
                ?.map((e) => ShiftRotation.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        primaryRotationId: json['primaryRotationId'] as String?,
        holidayCache: ((json['holidayCache'] as Map<String, dynamic>?) ?? {})
            .map((key, value) => MapEntry(
                  key,
                  HolidayInfo.fromJson(value as Map<String, dynamic>),
                )),
        holidaysLastUpdated: json['holidaysLastUpdated'] == null
            ? null
            : DateTime.parse(json['holidaysLastUpdated'] as String),
      );
}

/// 单个轮班定义。
///
/// 轮班是倒班的最小管理单元，包含班组列表、轮班状态列表、循环数、
/// 周期起始日期以及周期内的状态分配矩阵。
class ShiftRotation {
  /// 轮班唯一标识。
  final String id;

  /// 轮班显示名称。
  final String name;

  /// 周期起始日期。
  final DateTime baseDate;

  /// 循环周期天数，范围 1~30。
  ///
  /// 表示一个完整轮班周期包含的天数，决定 [assignments] 每行的列数。
  final int cycleDays;

  /// 班组列表。
  final List<ShiftGroup> groups;

  /// 轮班状态列表，如白班、上夜班、下夜班、休息。
  final List<ShiftSlot> slots;

  /// 周期状态分配矩阵。
  ///
  /// 外层索引对应 [groups] 的下标，内层索引对应周期内的第几天（0~cycleDays-1），
  /// 值为 [slots] 的下标。
  final List<List<int>> assignments;

  /// 是否为主要轮班。
  final bool isPrimary;

  const ShiftRotation({
    required this.id,
    required this.name,
    required this.baseDate,
    required this.cycleDays,
    required this.groups,
    required this.slots,
    required this.assignments,
    this.isPrimary = false,
  });

  static const int minCycleDays = 1;
  static const int maxCycleDays = 30;
  static const int minGroupCount = 1;
  static const int maxGroupCount = 8;

  /// 获取指定班组在周期内指定日期的状态下标。
  ///
  /// [groupIndex] 和 [dayIndex] 会被规范到有效范围内。
  int assignmentIndexFor(int groupIndex, int dayIndex) {
    final validGroup = groupIndex % groups.length;
    final validDay = dayIndex % cycleDays;
    return assignments[validGroup][validDay];
  }

  /// 获取指定班组在周期内指定日期的状态。
  ShiftSlot slotFor(int groupIndex, int dayIndex) {
    final slotIndex = assignmentIndexFor(groupIndex, dayIndex);
    return slots[slotIndex];
  }

  ShiftRotation copyWith({
    String? id,
    String? name,
    DateTime? baseDate,
    int? cycleDays,
    List<ShiftGroup>? groups,
    List<ShiftSlot>? slots,
    List<List<int>>? assignments,
    bool? isPrimary,
  }) =>
      ShiftRotation(
        id: id ?? this.id,
        name: name ?? this.name,
        baseDate: baseDate ?? this.baseDate,
        cycleDays: cycleDays ?? this.cycleDays,
        groups: groups ?? this.groups,
        slots: slots ?? this.slots,
        assignments: assignments ?? this.assignments,
        isPrimary: isPrimary ?? this.isPrimary,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseDate': baseDate.toIso8601String(),
        'cycleDays': cycleDays,
        'groups': groups.map((e) => e.toJson()).toList(),
        'slots': slots.map((e) => e.toJson()).toList(),
        'assignments': assignments,
        'isPrimary': isPrimary,
      };

  factory ShiftRotation.fromJson(Map<String, dynamic> json) {
    final groups = (json['groups'] as List<dynamic>)
        .map((e) => ShiftGroup.fromJson(e as Map<String, dynamic>))
        .toList();

    // 兼容旧数据：旧版本使用 cycleCount，周期天数 = groupCount * cycleCount。
    final cycleDays = json['cycleDays'] as int? ??
        (json['cycleCount'] as int? ?? 1) * max(groups.length, 1);

    return ShiftRotation(
      id: json['id'] as String,
      name: json['name'] as String,
      baseDate: DateTime.parse(json['baseDate'] as String),
      cycleDays: cycleDays,
      groups: groups,
      slots: (json['slots'] as List<dynamic>)
          .map((e) => ShiftSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      assignments: (json['assignments'] as List<dynamic>)
          .map((row) => (row as List<dynamic>).cast<int>())
          .toList(),
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}

/// 单个班组定义。
class ShiftGroup {
  /// 班组唯一标识。
  final String id;

  /// 班组显示名称。
  final String name;

  /// 班组颜色（ARGB 整数值）。
  final int colorValue;

  const ShiftGroup({
    required this.id,
    required this.name,
    this.colorValue = 0xFF_90A4AE,
  });

  ShiftGroup copyWith({
    String? id,
    String? name,
    int? colorValue,
  }) =>
      ShiftGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
      };

  factory ShiftGroup.fromJson(Map<String, dynamic> json) => ShiftGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['colorValue'] as int? ?? 0xFF_607D8B,
      );
}

/// 单个轮班状态定义。
class ShiftSlot {
  /// 状态名称，如“白班”。
  final String name;

  /// 开始时间，格式 HH:mm；休息状态可为空。
  final String? startTime;

  /// 结束时间，格式 HH:mm；休息状态可为空。
  final String? endTime;

  /// 是否为休息状态。
  final bool isRest;

  const ShiftSlot({
    required this.name,
    this.startTime,
    this.endTime,
    this.isRest = false,
  });

  ShiftSlot copyWith({
    String? name,
    String? startTime,
    String? endTime,
    bool? isRest,
  }) =>
      ShiftSlot(
        name: name ?? this.name,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        isRest: isRest ?? this.isRest,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'startTime': startTime,
        'endTime': endTime,
        'isRest': isRest,
      };

  factory ShiftSlot.fromJson(Map<String, dynamic> json) => ShiftSlot(
        name: json['name'] as String,
        startTime: json['startTime'] as String?,
        endTime: json['endTime'] as String?,
        isRest: json['isRest'] as bool? ?? false,
      );
}

/// 单天节假日信息。
class HolidayInfo {
  /// 节假日/调休名称，如“春节”、“劳动节补班”。
  final String name;

  /// 是否为法定节假日（休息日）。
  final bool isHoliday;

  /// 是否为调休上班日。
  final bool isWorkday;

  const HolidayInfo({
    required this.name,
    this.isHoliday = false,
    this.isWorkday = false,
  });

  HolidayInfo copyWith({
    String? name,
    bool? isHoliday,
    bool? isWorkday,
  }) =>
      HolidayInfo(
        name: name ?? this.name,
        isHoliday: isHoliday ?? this.isHoliday,
        isWorkday: isWorkday ?? this.isWorkday,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'isHoliday': isHoliday,
        'isWorkday': isWorkday,
      };

  factory HolidayInfo.fromJson(Map<String, dynamic> json) => HolidayInfo(
        name: json['name'] as String,
        isHoliday: json['isHoliday'] as bool? ?? false,
        isWorkday: json['isWorkday'] as bool? ?? false,
      );
}
