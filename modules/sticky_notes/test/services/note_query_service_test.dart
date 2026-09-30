import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_block.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_sort_mode.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_note.dart';
import 'package:sticky_notes_module/features/sticky_notes/services/note_query_service.dart';

/// 构造便签（默认时间可覆盖）。
StickyNote buildNote(
  String id, {
  String? title,
  String? body,
  DateTime? createdAt,
  DateTime? updatedAt,
  String? categoryId,
  bool isPinned = false,
  DateTime? pinnedAt,
}) {
  final base = DateTime(2026, 9, 1, 8);
  return StickyNote(
    id: id,
    title: title ?? id,
    content: body == null
        ? const []
        : [
            ParagraphBlock(inlines: [NoteInline(text: body)]),
          ],
    categoryId: categoryId,
    isPinned: isPinned,
    pinnedAt: pinnedAt,
    createdAt: createdAt ?? base,
    updatedAt: updatedAt ?? base,
  );
}

void main() {
  const service = NoteQueryService();

  group('NoteQueryService.sort', () {
    test('置顶恒排在普通便签之前（即使更新时间更旧）', () {
      final pinned = buildNote('p',
          isPinned: true,
          pinnedAt: DateTime(2026, 9, 5),
          updatedAt: DateTime(2026, 9, 1));
      final normal = buildNote('n', updatedAt: DateTime(2026, 9, 9));

      final sorted = service.sort([normal, pinned], NoteSortMode.updatedDesc);
      expect(sorted.map((e) => e.id).toList(), ['p', 'n']);
    });

    test('置顶内部按 pinnedAt 倒序', () {
      final older = buildNote('a',
          isPinned: true, pinnedAt: DateTime(2026, 9, 2));
      final newer = buildNote('b',
          isPinned: true, pinnedAt: DateTime(2026, 9, 6));

      final sorted = service.sort([older, newer], NoteSortMode.updatedDesc);
      expect(sorted.map((e) => e.id).toList(), ['b', 'a']);
    });

    test('updatedDesc 按更新时间倒序', () {
      final a = buildNote('a', updatedAt: DateTime(2026, 9, 3));
      final b = buildNote('b', updatedAt: DateTime(2026, 9, 7));
      final sorted = service.sort([a, b], NoteSortMode.updatedDesc);
      expect(sorted.map((e) => e.id).toList(), ['b', 'a']);
    });

    test('createdDesc 按创建时间倒序', () {
      final a = buildNote('a', createdAt: DateTime(2026, 8, 3));
      final b = buildNote('b', createdAt: DateTime(2026, 8, 7));
      final sorted = service.sort([a, b], NoteSortMode.createdDesc);
      expect(sorted.map((e) => e.id).toList(), ['b', 'a']);
    });

    test('titleAsc 按标题字母序', () {
      final a = buildNote('a', title: 'Banana');
      final b = buildNote('b', title: 'Apple');
      final sorted = service.sort([a, b], NoteSortMode.titleAsc);
      expect(sorted.map((e) => e.id).toList(), ['b', 'a']);
    });

    test('同排序键按 createdAt 升序兜底', () {
      final sameUpdated = DateTime(2026, 9, 4);
      final older = buildNote('older',
          updatedAt: sameUpdated, createdAt: DateTime(2026, 8, 1));
      final newer = buildNote('newer',
          updatedAt: sameUpdated, createdAt: DateTime(2026, 8, 2));

      final sorted = service.sort([newer, older], NoteSortMode.updatedDesc);
      expect(sorted.map((e) => e.id).toList(), ['older', 'newer']);
    });
  });

  group('NoteQueryService.filterByCategory', () {
    final notes = [
      buildNote('a', categoryId: 'work'),
      buildNote('b', categoryId: 'life'),
      buildNote('c'),
    ];

    test('null 表示不限', () {
      expect(service.filterByCategory(notes, null).length, 3);
    });

    test('noCategoryKey 筛选无分类', () {
      final filtered = service.filterByCategory(notes, NoteQueryService.noCategoryKey);
      expect(filtered.map((e) => e.id).toList(), ['c']);
    });

    test('按分类 id 精确匹配', () {
      final filtered = service.filterByCategory(notes, 'work');
      expect(filtered.map((e) => e.id).toList(), ['a']);
    });
  });

  group('NoteQueryService.query', () {
    test('筛选 + 排序组合（置顶优先）', () {
      final notes = [
        buildNote('a', categoryId: 'work', updatedAt: DateTime(2026, 9, 9)),
        buildNote('b', categoryId: 'work', isPinned: true, pinnedAt: DateTime(2026, 9, 1), updatedAt: DateTime(2026, 9, 1)),
        buildNote('c', categoryId: 'life'),
      ];

      final result = service.query(notes, mode: NoteSortMode.updatedDesc, categoryId: 'work');
      expect(result.map((e) => e.id).toList(), ['b', 'a']);
    });

    test('不筛选时不丢失任何便签', () {
      final notes = [
        buildNote('a', categoryId: 'work'),
        buildNote('b'),
      ];
      final result = service.query(notes, mode: NoteSortMode.updatedDesc);
      expect(result.length, 2);
    });
  });

  group('NoteQueryService.search', () {
    test('关键字为空返回空列表（调用方需回退 query）', () {
      final notes = [buildNote('a', title: '甲')];
      final hits = service.search(
        notes,
        mode: NoteSortMode.updatedDesc,
        keyword: '  ',
      );
      expect(hits, isEmpty);
    });

    test('标题与正文命中均可检索', () {
      final notes = [
        buildNote('t', title: '会议纪要'),
        buildNote('b', title: '无关', body: '会议记录'),
        buildNote('n', title: '无关'),
      ];

      final hits = service.search(
        notes,
        mode: NoteSortMode.updatedDesc,
        keyword: '会议',
      );
      expect(hits.map((e) => e.note.id).toList(), ['t', 'b']);
    });

    test('与分类筛选叠加生效', () {
      final notes = [
        buildNote('w', title: '会议', categoryId: 'work'),
        buildNote('l', title: '会议', categoryId: 'life'),
      ];

      final hits = service.search(
        notes,
        mode: NoteSortMode.updatedDesc,
        categoryId: 'work',
        keyword: '会议',
      );
      expect(hits.map((e) => e.note.id).toList(), ['w']);
    });

    test('同分时沿用排序兜底顺序（置顶优先）', () {
      final notes = [
        buildNote('n', title: '会议', updatedAt: DateTime(2026, 9, 9)),
        buildNote('p',
            title: '会议', isPinned: true, pinnedAt: DateTime(2026, 9, 1)),
      ];

      final hits = service.search(
        notes,
        mode: NoteSortMode.updatedDesc,
        keyword: '会议',
      );
      expect(hits.map((e) => e.note.id).toList(), ['p', 'n']);
    });

    test('模糊匹配：子序列关键字可命中', () {
      final notes = [buildNote('a', title: '工作汇报')];
      final hits = service.search(
        notes,
        mode: NoteSortMode.updatedDesc,
        keyword: '工报',
      );
      expect(hits.single.titleMatches, [0, 3]);
    });
  });
}
