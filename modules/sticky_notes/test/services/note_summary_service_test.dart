import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_note.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_notes_config.dart';
import 'package:sticky_notes_module/features/sticky_notes/services/note_summary_service.dart';

void main() {
  const service = NoteSummaryService();
  final now = DateTime(2026, 9, 1);

  StickyNote note(String id, {bool isPinned = false}) => StickyNote(
        id: id,
        title: id,
        isPinned: isPinned,
        pinnedAt: isPinned ? now : null,
        createdAt: now,
        updatedAt: now,
      );

  group('NoteSummaryService', () {
    test('空列表与默认配置', () {
      final summary = service.computeSummary([], const StickyNotesConfig());
      expect(summary.total, 0);
      expect(summary.pinnedCount, 0);
      expect(summary.categoryCount, 3);
    });

    test('统计总数、置顶数与分类数', () {
      final summary = service.computeSummary(
        [note('a', isPinned: true), note('b'), note('c', isPinned: true)],
        const StickyNotesConfig(categories: []),
      );
      expect(summary.total, 3);
      expect(summary.pinnedCount, 2);
      // 空分类列表在 fromJson 时回退默认，但直接构造时保持为空。
      expect(summary.categoryCount, 0);
    });
  });
}
