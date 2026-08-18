import 'recurrence_rule.dart';
import 'todo_image_attachment.dart';
import 'todo_priority.dart';

/// 单个待办项。
class TodoItem {
  const TodoItem({
    required this.id,
    required this.title,
    this.details,
    this.images = const [],
    this.categoryId,
    required this.priority,
    this.dueDate,
    this.recurrenceRules = const [],
    this.remindMinutes,
    this.remindEnabled = true,
    this.executionTimeMinutes = 540,
    this.remindAtExecution = true,
    this.remindEarly = true,
    this.isCompleted = false,
    this.completedAt,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 唯一标识。
  final String id;

  /// 名称（主要内容），主页面仅显示此项。
  final String title;

  /// 详情文本。
  final String? details;

  /// 详情图片附件。
  final List<TodoImageAttachment> images;

  /// 关联 [TodoCategory.id]，可为 null。
  final String? categoryId;

  /// 优先级。
  final TodoPriority priority;

  /// 期限（一次性事项的到期日；循环事项由规则计算）。
  final DateTime? dueDate;

  /// 循环规则列表；空列表表示一次性（不循环）。
  final List<RecurrenceRule> recurrenceRules;

  /// 提前提醒分钟数，null 表示使用默认。
  final int? remindMinutes;

  /// 是否启用本条待办的提醒（单条开关）。
  ///
  /// 总开关仍受全局 [TodoConfig.remindEnabled] 控制。
  final bool remindEnabled;

  /// 命中日的执行时刻（自 00:00 起分钟数，如 09:00 = 540）。
  final int executionTimeMinutes;

  /// 是否在执行时刻触发一次提醒（执行时刻提醒）。
  final bool remindAtExecution;

  /// 是否在执行时刻前 N 分钟触发一次提醒（提前提醒）。
  final bool remindEarly;

  /// 是否已完成。
  final bool isCompleted;

  /// 完成时间。
  final DateTime? completedAt;

  /// 是否已列入待办历史。
  final bool isArchived;

  /// 创建时间。
  final DateTime createdAt;

  /// 最后更新时间。
  final DateTime updatedAt;

  /// 是否为一次性事项（不循环）。
  bool get isOneTime => recurrenceRules.isEmpty;

  /// 是否为循环事项。
  bool get isRecurring => recurrenceRules.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (details != null) 'details': details,
        'images': images.map((e) => e.toJson()).toList(),
        if (categoryId != null) 'categoryId': categoryId,
        'priority': priority.jsonValue,
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
        'recurrenceRules': recurrenceRules.map((e) => e.toJson()).toList(),
        if (remindMinutes != null) 'remindMinutes': remindMinutes,
        'remindEnabled': remindEnabled,
        'executionTimeMinutes': executionTimeMinutes,
        'remindAtExecution': remindAtExecution,
        'remindEarly': remindEarly,
        'isCompleted': isCompleted,
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        'isArchived': isArchived,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        id: json['id'] as String,
        title: json['title'] as String,
        details: json['details'] as String?,
        images: (json['images'] as List<dynamic>?)
                ?.map(
                    (e) => TodoImageAttachment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        categoryId: json['categoryId'] as String?,
        priority: TodoPriority.fromJson(json['priority'] as String),
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        recurrenceRules: (json['recurrenceRules'] as List<dynamic>?)
                ?.map(
                    (e) => RecurrenceRule.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        remindMinutes: json['remindMinutes'] as int?,
        remindEnabled: json['remindEnabled'] as bool? ?? true,
        executionTimeMinutes: json['executionTimeMinutes'] as int? ?? 540,
        remindAtExecution: json['remindAtExecution'] as bool? ?? true,
        remindEarly: json['remindEarly'] as bool? ?? true,
        isCompleted: json['isCompleted'] as bool? ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        isArchived: json['isArchived'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  TodoItem copyWith({
    String? id,
    String? title,
    String? details,
    List<TodoImageAttachment>? images,
    String? categoryId,
    TodoPriority? priority,
    DateTime? dueDate,
    List<RecurrenceRule>? recurrenceRules,
    int? remindMinutes,
    bool? remindEnabled,
    int? executionTimeMinutes,
    bool? remindAtExecution,
    bool? remindEarly,
    bool? isCompleted,
    DateTime? completedAt,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TodoItem(
        id: id ?? this.id,
        title: title ?? this.title,
        details: details ?? this.details,
        images: images ?? this.images,
        categoryId: categoryId ?? this.categoryId,
        priority: priority ?? this.priority,
        dueDate: dueDate ?? this.dueDate,
        recurrenceRules: recurrenceRules ?? this.recurrenceRules,
        remindMinutes: remindMinutes ?? this.remindMinutes,
        remindEnabled: remindEnabled ?? this.remindEnabled,
        executionTimeMinutes: executionTimeMinutes ?? this.executionTimeMinutes,
        remindAtExecution: remindAtExecution ?? this.remindAtExecution,
        remindEarly: remindEarly ?? this.remindEarly,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt: completedAt ?? this.completedAt,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}