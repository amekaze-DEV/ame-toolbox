import 'holiday_info.dart';
import 'todo_category.dart';

/// 模块级根配置。
class TodoConfig {
  /// 模块内置默认分类（spec §2.3）。
  static const List<TodoCategory> defaultCategories = [
    TodoCategory(id: 'work', name: '工作', colorValue: 0xFF1565C0, displayOrder: 0),
    TodoCategory(id: 'life', name: '生活', colorValue: 0xFF2D7D46, displayOrder: 1),
    TodoCategory(id: 'other', name: '其他', colorValue: 0xFF6A1B9A, displayOrder: 2),
  ];

  const TodoConfig({
    this.categories = defaultCategories,
    this.remindEnabled = true,
    this.defaultRemindMinutes = 30,
    this.dailyTop = false,
    this.holidayCache = const {},
    this.holidaysLastUpdated,
  });

  /// 分类列表，按 displayOrder 排序。
  final List<TodoCategory> categories;

  /// 到期提醒总开关，默认 true。
  final bool remindEnabled;

  /// 默认提前提醒分钟数，默认 30。
  final int defaultRemindMinutes;

  /// 日常事项是否置顶显示。
  final bool dailyTop;

  /// 节假日缓存，key 为 yyyy-MM-dd。
  final Map<String, HolidayInfo> holidayCache;

  /// 节假日数据最后更新时间。
  final DateTime? holidaysLastUpdated;

  static const _schemaVersion = 1;

  Map<String, dynamic> toJson() => {
        'schemaVersion': _schemaVersion,
        'categories': categories.map((c) => c.toJson()).toList(),
        'remindEnabled': remindEnabled,
        'defaultRemindMinutes': defaultRemindMinutes,
        'dailyTop': dailyTop,
        'holidayCache': holidayCache.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        'holidaysLastUpdated': holidaysLastUpdated?.toIso8601String(),
      };

  factory TodoConfig.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'] as int? ?? 1;
    // 当前仅支持 schemaVersion 1；后续版本可在此分支迁移逻辑。
    assert(schemaVersion == 1, 'Unsupported TodoConfig schema version: $schemaVersion');
    return TodoConfig(
      categories: switch (json['categories'] as List<dynamic>?) {
        null => defaultCategories,
        final list when list.isEmpty => defaultCategories,
        final list => list
            .map((e) => TodoCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      },
      remindEnabled: json['remindEnabled'] as bool? ?? true,
      defaultRemindMinutes: json['defaultRemindMinutes'] as int? ?? 30,
      dailyTop: json['dailyTop'] as bool? ?? false,
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

  TodoConfig copyWith({
    List<TodoCategory>? categories,
    bool? remindEnabled,
    int? defaultRemindMinutes,
    bool? dailyTop,
    Map<String, HolidayInfo>? holidayCache,
    DateTime? holidaysLastUpdated,
    bool clearHolidaysLastUpdated = false,
  }) =>
      TodoConfig(
        categories: categories ?? this.categories,
        remindEnabled: remindEnabled ?? this.remindEnabled,
        defaultRemindMinutes: defaultRemindMinutes ?? this.defaultRemindMinutes,
        dailyTop: dailyTop ?? this.dailyTop,
        holidayCache: holidayCache ?? this.holidayCache,
        holidaysLastUpdated: clearHolidaysLastUpdated
            ? null
            : (holidaysLastUpdated ?? this.holidaysLastUpdated),
      );
}