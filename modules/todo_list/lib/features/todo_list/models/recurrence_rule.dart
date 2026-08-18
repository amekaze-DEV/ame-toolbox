import 'recurrence_pattern.dart';

/// 循环周期规则：包含日期计算策略与有效期。
///
/// 一个 [TodoItem] 可绑定多个 [RecurrenceRule]，所有规则独立计算后合并去重。
class RecurrenceRule {
  const RecurrenceRule({
    required this.pattern,
    required this.startDate,
    this.endDate,
  });

  /// 14 种周期方式之一。
  final RecurrencePattern pattern;

  /// 起始时间（必填）。
  final DateTime startDate;

  /// 终止时间（可空；空 = 自动无限循环）。
  final DateTime? endDate;

  Map<String, dynamic> toJson() => {
        'pattern': pattern.toJson(),
        'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
      };

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) => RecurrenceRule(
        pattern:
            RecurrencePattern.fromJson(json['pattern'] as Map<String, dynamic>),
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
      );
}