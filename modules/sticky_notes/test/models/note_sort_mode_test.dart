import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_sort_mode.dart';

void main() {
  group('NoteSortMode', () {
    test('jsonValue 与 fromJson 往返', () {
      for (final mode in NoteSortMode.values) {
        expect(NoteSortMode.fromJson(mode.jsonValue), mode);
      }
    });

    test('未知值抛出 ArgumentError', () {
      expect(() => NoteSortMode.fromJson('unknown'), throwsArgumentError);
    });

    test('displayName 非空', () {
      for (final mode in NoteSortMode.values) {
        expect(mode.displayName, isNotEmpty);
      }
    });
  });
}
