import '../models/note_summary.dart';
import '../models/sticky_note.dart';
import '../models/sticky_notes_config.dart';

/// 摘要聚合服务（纯函数）。
///
/// 聚合便签总数、置顶数与分类数（spec §2.9）。
class NoteSummaryService {
  const NoteSummaryService();

  /// 聚合摘要。
  NoteSummary computeSummary(
    List<StickyNote> notes,
    StickyNotesConfig config,
  ) {
    var pinned = 0;
    for (final note in notes) {
      if (note.isPinned) pinned++;
    }
    return NoteSummary(
      total: notes.length,
      pinnedCount: pinned,
      categoryCount: config.categories.length,
    );
  }
}
