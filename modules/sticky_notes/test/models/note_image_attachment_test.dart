import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_image_attachment.dart';

void main() {
  group('NoteImageAttachment', () {
    test('JSON 往返', () {
      final attachment = NoteImageAttachment(
        id: 'img_1',
        dataBase64: 'iVBORw0KGgo=',
        createdAt: DateTime(2026, 9, 1, 12),
      );
      final restored = NoteImageAttachment.fromJson(attachment.toJson());
      expect(restored.id, 'img_1');
      expect(restored.dataBase64, 'iVBORw0KGgo=');
      expect(restored.createdAt, DateTime(2026, 9, 1, 12));
    });
  });
}
