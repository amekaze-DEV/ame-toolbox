import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_summary.dart';

void main() {
  group('NoteSummary', () {
    test('默认全为 0', () {
      const summary = NoteSummary();
      expect(summary.total, 0);
      expect(summary.pinnedCount, 0);
      expect(summary.categoryCount, 0);
    });

    test('自定义值', () {
      const summary = NoteSummary(total: 12, pinnedCount: 3, categoryCount: 4);
      expect(summary.total, 12);
      expect(summary.pinnedCount, 3);
      expect(summary.categoryCount, 4);
    });
  });
}
