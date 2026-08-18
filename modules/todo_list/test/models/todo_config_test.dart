import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/todo_category.dart';
import 'package:todo_list_module/features/todo_list/models/todo_config.dart';

void main() {
  group('TodoConfig', () {
    test('默认配置包含内置分类', () {
      final config = TodoConfig();
      expect(config.categories.length, 3);
      expect(config.categories.map((c) => c.id).toList(),
          <String>['work', 'life', 'other']);
      expect(config.remindEnabled, true);
      expect(config.defaultRemindMinutes, 30);
      expect(config.dailyTop, false);
    });

    test('toJson / fromJson 往返正确', () {
      final config = TodoConfig(
        categories: const [
          TodoCategory(id: 'custom', name: '自定义', colorValue: 0xFFFF0000, displayOrder: 0),
        ],
        remindEnabled: false,
        defaultRemindMinutes: 15,
        dailyTop: true,
      );

      final json = config.toJson();
      expect(json['schemaVersion'], 1);
      expect(json['remindEnabled'], false);
      expect(json['defaultRemindMinutes'], 15);
      expect(json['dailyTop'], true);

      final restored = TodoConfig.fromJson(json);
      expect(restored.categories.length, 1);
      expect(restored.categories.first.id, 'custom');
      expect(restored.remindEnabled, false);
      expect(restored.defaultRemindMinutes, 15);
      expect(restored.dailyTop, true);
    });

    test('fromJson 兼容缺失 categories 时使用默认分类', () {
      final restored = TodoConfig.fromJson(const {
        'schemaVersion': 1,
        'remindEnabled': true,
        'defaultRemindMinutes': 30,
        'dailyTop': false,
      });
      expect(restored.categories.length, 3);
    });

    test('copyWith 保留未修改字段', () {
      final config = TodoConfig();
      final updated = config.copyWith(dailyTop: true);
      expect(updated.dailyTop, true);
      expect(updated.remindEnabled, config.remindEnabled);
      expect(updated.categories, config.categories);
    });
  });
}