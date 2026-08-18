import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/todo_list_summary.dart';

void main() {
  group('TodoListSummary', () {
    test('字段值正确保存', () {
      const summary = TodoListSummary(
        total: 10,
        pendingCount: 5,
        todayCount: 2,
        overdueCount: 1,
      );

      expect(summary.total, 10);
      expect(summary.pendingCount, 5);
      expect(summary.todayCount, 2);
      expect(summary.overdueCount, 1);
    });
  });
}