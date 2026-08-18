import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/todo_category.dart';

void main() {
  group('TodoCategory', () {
    const category = TodoCategory(
      id: 'work',
      name: '工作',
      colorValue: 0xFF1565C0,
      displayOrder: 2,
    );

    test('toJson / fromJson 往返正确', () {
      final json = category.toJson();
      expect(json['id'], 'work');
      expect(json['name'], '工作');
      expect(json['colorValue'], 0xFF1565C0);
      expect(json['displayOrder'], 2);

      final restored = TodoCategory.fromJson(json);
      expect(restored.id, category.id);
      expect(restored.name, category.name);
      expect(restored.colorValue, category.colorValue);
      expect(restored.displayOrder, category.displayOrder);
    });
  });
}