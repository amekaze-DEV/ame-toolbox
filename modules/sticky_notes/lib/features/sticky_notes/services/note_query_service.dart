import '../models/note_sort_mode.dart';
import '../models/sticky_note.dart';

/// 便签查询 / 排序 / 筛选服务（纯函数）。
///
/// - 排序（spec §4.1）：置顶恒排在普通便签之前；置顶内部按 `pinnedAt`
///   倒序，再按所选排序方式；普通便签按排序方式；同排序键按 `createdAt`
///   升序兜底。
/// - 筛选：按分类筛选，`null` 表示不限。
class NoteQueryService {
  const NoteQueryService();

  /// 无分类筛选标识（筛选未归类的便签）。
  static const noCategoryKey = '__none__';

  /// 排序（不改动原列表）。
  List<StickyNote> sort(List<StickyNote> notes, NoteSortMode mode) {
    final sorted = List<StickyNote>.of(notes);
    sorted.sort((a, b) {
      // 置顶恒排在普通便签之前。
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      // 置顶内部：按 pinnedAt 倒序。
      if (a.isPinned && b.isPinned) {
        final pa = a.pinnedAt;
        final pb = b.pinnedAt;
        if (pa != null && pb != null) {
          final byPin = pb.compareTo(pa);
          if (byPin != 0) return byPin;
        } else if (pa != null) {
          return -1;
        } else if (pb != null) {
          return 1;
        }
      }
      final byMode = _compareByMode(a, b, mode);
      if (byMode != 0) return byMode;
      // 同排序键：按 createdAt 升序兜底。
      return a.createdAt.compareTo(b.createdAt);
    });
    return sorted;
  }

  int _compareByMode(StickyNote a, StickyNote b, NoteSortMode mode) =>
      switch (mode) {
        NoteSortMode.updatedDesc => b.updatedAt.compareTo(a.updatedAt),
        NoteSortMode.createdDesc => b.createdAt.compareTo(a.createdAt),
        NoteSortMode.titleAsc => a.title.compareTo(b.title),
      };

  /// 按分类筛选。
  ///
  /// [categoryId] 为 null 时不限；[noCategoryKey] 筛选无分类便签；
  /// 其他值按 `categoryId` 精确匹配。
  List<StickyNote> filterByCategory(List<StickyNote> notes, String? categoryId) {
    if (categoryId == null) return List<StickyNote>.of(notes);
    if (categoryId == noCategoryKey) {
      return notes.where((e) => e.categoryId == null).toList();
    }
    return notes.where((e) => e.categoryId == categoryId).toList();
  }

  /// 筛选 + 排序组合查询。
  List<StickyNote> query(
    List<StickyNote> notes, {
    required NoteSortMode mode,
    String? categoryId,
  }) =>
      sort(filterByCategory(notes, categoryId), mode);
}
