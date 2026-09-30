import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_block.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_note.dart';
import 'package:sticky_notes_module/features/sticky_notes/services/note_search_service.dart';

/// 构造便签（正文为单个段落块）。
StickyNote buildNote(String id, {String? title, String? body}) {
  final base = DateTime(2026, 9, 1, 8);
  return StickyNote(
    id: id,
    title: title ?? id,
    content: body == null
        ? const []
        : [
            ParagraphBlock(inlines: [NoteInline(text: body)]),
          ],
    createdAt: base,
    updatedAt: base,
  );
}

void main() {
  const service = NoteSearchService();

  group('normalizeKeyword', () {
    test('去除首尾空白并忽略大小写', () {
      expect(NoteSearchService.normalizeKeyword('  AbC '), 'abc');
    });

    test('空白或空串返回 null', () {
      expect(NoteSearchService.normalizeKeyword(''), isNull);
      expect(NoteSearchService.normalizeKeyword('   '), isNull);
    });
  });

  group('matchIndices', () {
    test('子串命中返回连续下标', () {
      expect(NoteSearchService.matchIndices('工作汇报', '汇报'), [2, 3]);
    });

    test('忽略大小写', () {
      expect(
        NoteSearchService.matchIndices('Meeting Notes', 'MEETING'),
        [0, 1, 2, 3, 4, 5, 6],
      );
    });

    test('模糊：子序列命中（允许跳过中间字符）', () {
      // '工作汇报' 中「报」位于下标 3。
      expect(NoteSearchService.matchIndices('工作汇报', '工报'), [0, 3]);
    });

    test('顺序不符不命中', () {
      expect(NoteSearchService.matchIndices('工作汇报', '报工'), isNull);
    });

    test('缺少字符不命中', () {
      expect(NoteSearchService.matchIndices('工作', '工作汇报'), isNull);
    });

    test('空文本或空关键字返回 null', () {
      expect(NoteSearchService.matchIndices('', 'a'), isNull);
      expect(NoteSearchService.matchIndices('a', ''), isNull);
    });
  });

  group('scoreOf', () {
    test('子串命中高于子序列命中', () {
      expect(
        NoteSearchService.scoreOf([0, 1]),
        greaterThan(NoteSearchService.scoreOf([0, 2])),
      );
    });

    test('命中位置越靠前得分越高', () {
      expect(
        NoteSearchService.scoreOf([0, 1]),
        greaterThan(NoteSearchService.scoreOf([5, 6])),
      );
    });

    test('连续程度越高得分越高', () {
      expect(
        NoteSearchService.scoreOf([0, 1, 2]),
        greaterThan(NoteSearchService.scoreOf([0, 2, 3])),
      );
    });
  });

  group('match', () {
    test('标题命中优先于正文命中', () {
      final titleHit = service.match(buildNote('a', title: '会议', body: '无关'), '会议')!;
      final bodyHit = service.match(buildNote('b', title: '无关', body: '会议纪要'), '会议')!;

      expect(titleHit.score, greaterThan(bodyHit.score));
      expect(titleHit.titleMatches, isNotEmpty);
      expect(titleHit.bodyMatches, isEmpty);
      expect(bodyHit.titleMatches, isEmpty);
      expect(bodyHit.bodyMatches, isNotEmpty);
    });

    test('不命中返回 null', () {
      expect(service.match(buildNote('a', title: '甲'), '乙'), isNull);
    });

    test('正文跨块纯文本参与检索', () {
      final base = DateTime(2026, 9, 1);
      final note = StickyNote(
        id: 'multi',
        title: '标题',
        content: const [
          ParagraphBlock(inlines: [NoteInline(text: '第一段')]),
          ParagraphBlock(inlines: [NoteInline(text: '第二段')]),
        ],
        createdAt: base,
        updatedAt: base,
      );

      final hit = service.match(note, '二段')!;
      expect(hit.bodyMatches, isNotEmpty);
      // 纯文本为 "第一段\n第二段"，命中下标落在第二段。
      expect(hit.bodyMatches.first, greaterThan(3));
    });
  });

  group('search', () {
    test('按相关度降序，标题命中排在正文命中之前', () {
      final notes = [
        buildNote('body', title: '无关', body: '会议纪要'),
        buildNote('title', title: '会议纪要'),
      ];

      final hits = service.search(notes, '会议');
      expect(hits.map((e) => e.note.id).toList(), ['title', 'body']);
    });

    test('关键字为空或仅空白返回空列表', () {
      final notes = [buildNote('a', title: '甲')];
      expect(service.search(notes, ''), isEmpty);
      expect(service.search(notes, '   '), isEmpty);
    });

    test('同分保持输入顺序', () {
      final notes = [
        buildNote('a', title: '会议'),
        buildNote('b', title: '会议'),
      ];

      final hits = service.search(notes, '会议');
      expect(hits.map((e) => e.note.id).toList(), ['a', 'b']);
    });

    test('高亮下标与源文本一致', () {
      final hits = service.search([buildNote('a', title: '工作汇报')], '工报');
      expect(hits.single.titleMatches, [0, 3]);
      expect(hits.single.titleHighlight, {0, 3});
    });
  });
}