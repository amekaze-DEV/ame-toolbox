import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_pattern.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_rule.dart';

void main() {
  group('RecurrenceRule', () {
    final startDate = DateTime(2026, 8, 1);
    final endDate = DateTime(2026, 12, 31);

    test('toJson / fromJson 往返正确（无终止时间）', () {
      const pattern = WeeklyPattern(interval: 1, weekdays: {1, 4});
      final rule = RecurrenceRule(pattern: pattern, startDate: startDate);

      final json = rule.toJson();
      expect(json['pattern']['type'], 'weekly');
      expect(json['startDate'], '2026-08-01T00:00:00.000');
      expect(json.containsKey('endDate'), false);

      final restored = RecurrenceRule.fromJson(json);
      expect(restored.pattern, isA<WeeklyPattern>());
      expect(restored.startDate, startDate);
      expect(restored.endDate, null);
    });

    test('toJson / fromJson 往返正确（有终止时间）', () {
      const pattern = EveryXDaysPattern(interval: 2, days: {1});
      final rule = RecurrenceRule(
        pattern: pattern,
        startDate: startDate,
        endDate: endDate,
      );

      final json = rule.toJson();
      expect(json['endDate'], '2026-12-31T00:00:00.000');

      final restored = RecurrenceRule.fromJson(json);
      expect(restored.endDate, endDate);
    });
  });
}