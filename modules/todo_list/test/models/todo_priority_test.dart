import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/todo_priority.dart';

void main() {
  group('TodoPriority', () {
    test('jsonValue 与 fromJson 一一对应', () {
      for (final priority in TodoPriority.values) {
        expect(TodoPriority.fromJson(priority.jsonValue), priority);
      }
    });

    test('displayName 为中文', () {
      expect(TodoPriority.highest.displayName, '最高');
      expect(TodoPriority.high.displayName, '高');
      expect(TodoPriority.medium.displayName, '中');
      expect(TodoPriority.normal.displayName, '一般');
      expect(TodoPriority.daily.displayName, '日常');
    });

    test('未知 json 值抛出 ArgumentError', () {
      expect(() => TodoPriority.fromJson('unknown'), throwsArgumentError);
    });
  });
}