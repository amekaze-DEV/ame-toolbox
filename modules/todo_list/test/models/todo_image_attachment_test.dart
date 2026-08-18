import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/todo_image_attachment.dart';

void main() {
  group('TodoImageAttachment', () {
    final createdAt = DateTime(2026, 8, 12, 10, 30);
    late TodoImageAttachment attachment;

    setUp(() {
      attachment = TodoImageAttachment(
        id: 'img-1',
        dataBase64: 'iVBORw0KGgo=',
        createdAt: createdAt,
      );
    });

    test('toJson / fromJson 往返正确', () {
      final json = attachment.toJson();
      expect(json['id'], 'img-1');
      expect(json['dataBase64'], 'iVBORw0KGgo=');
      expect(json['createdAt'], '2026-08-12T10:30:00.000');

      final restored = TodoImageAttachment.fromJson(json);
      expect(restored.id, attachment.id);
      expect(restored.dataBase64, attachment.dataBase64);
      expect(restored.createdAt, attachment.createdAt);
    });
  });
}