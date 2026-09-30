import 'dart:math' as math;

import '../models/sticky_note.dart';
import 'note_rich_text_parser.dart';

/// 单条便签的检索命中结果。
class NoteSearchHit {
  const NoteSearchHit({
    required this.note,
    required this.score,
    required this.titleMatches,
    required this.bodyMatches,
  });

  /// 命中的便签。
  final StickyNote note;

  /// 相关度得分（越大越相关；标题命中恒高于正文命中）。
  final int score;

  /// 标题中的命中字符下标（升序）。
  final List<int> titleMatches;

  /// 正文纯文本中的命中字符下标（升序）。
  final List<int> bodyMatches;

  /// 标题命中区间集合（供高亮渲染）。
  Set<int> get titleHighlight => titleMatches.toSet();

  /// 正文命中区间集合（供高亮渲染）。
  Set<int> get bodyHighlight => bodyMatches.toSet();
}

/// 便签关键字检索服务（纯函数）。
///
/// - 检索范围：标题 + 正文纯文本（spec §3.6）；附件（内嵌图片）暂不参与检索；
/// - 模糊匹配：先按忽略大小写的**子串**匹配，否则退化为**子序列**匹配
///   （输入「工报」可命中「工作汇报」）；
/// - 打分：标题命中恒优先于正文命中；子串命中优于子序列命中；
///   命中位置越靠前、连续程度越高，得分越高。
class NoteSearchService {
  const NoteSearchService();

  static const NoteRichTextParser _parser = NoteRichTextParser();

  /// 子串命中基准分（含 query 长度与起始位置权重）。
  static const int _exactBase = 1000;

  /// 子序列命中基准分与上限（保证恒低于任意子串命中）。
  static const int _fuzzyBase = 400;
  static const int _fuzzyMax = 700;

  /// 标题命中加成（保证标题命中恒排在正文命中之前）。
  static const int _titleBonus = 2000;

  /// 归一化关键字：去除首尾空白并忽略大小写；为空时返回 null（不启用检索）。
  static String? normalizeKeyword(String keyword) {
    final trimmed = keyword.trim().toLowerCase();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// 在 [notes] 中检索关键字。
  ///
  /// 返回按相关度降序排列的命中结果；同分时保持 [notes] 的原有顺序。
  /// 关键字为空（或仅空白）时返回空列表。
  List<NoteSearchHit> search(List<StickyNote> notes, String keyword) {
    final query = normalizeKeyword(keyword);
    if (query == null) return const [];

    final hits = <NoteSearchHit>[];
    for (final note in notes) {
      final hit = match(note, query);
      if (hit != null) hits.add(hit);
    }

    // 装饰下标后排序：同分保持输入顺序（稳定排序）。
    final indexed = [
      for (var i = 0; i < hits.length; i++) (index: i, hit: hits[i]),
    ];
    indexed.sort((a, b) {
      final byScore = b.hit.score.compareTo(a.hit.score);
      return byScore != 0 ? byScore : a.index.compareTo(b.index);
    });
    return [for (final entry in indexed) entry.hit];
  }

  /// 对单条便签做匹配；不命中返回 null。
  NoteSearchHit? match(StickyNote note, String keyword) {
    final query = normalizeKeyword(keyword);
    if (query == null) return null;

    final titleIndices = matchIndices(note.title, query);
    final bodyText = _parser.toPlainText(note.content);
    final bodyIndices = matchIndices(bodyText, query);
    if (titleIndices == null && bodyIndices == null) return null;

    final titleScore = titleIndices == null ? null : scoreOf(titleIndices);
    final bodyScore = bodyIndices == null ? null : scoreOf(bodyIndices);
    // 标题命中优先于正文命中。
    final score =
        titleScore != null ? _titleBonus + titleScore : bodyScore!;

    return NoteSearchHit(
      note: note,
      score: score,
      titleMatches: titleIndices ?? const [],
      bodyMatches: bodyIndices ?? const [],
    );
  }

  /// 模糊匹配：返回 [query] 在 [text] 中的命中字符下标（升序）；不命中返回 null。
  ///
  /// 优先按忽略大小写的子串匹配；不成立时按子序列匹配
  /// （各字符按序出现即可，允许跳过中间字符）。
  static List<int>? matchIndices(String text, String query) {
    if (text.isEmpty || query.isEmpty) return null;

    final q = query.toLowerCase();
    final lower = text.toLowerCase();
    // toLowerCase 不改变长度时（中英文等常见情况）可安全用于子串定位。
    if (lower.length == text.length) {
      final exact = lower.indexOf(q);
      if (exact >= 0) {
        return [for (var i = 0; i < q.length; i++) exact + i];
      }
    }

    // 子序列匹配：逐字符忽略大小写比较，索引始终基于原文。
    final indices = <int>[];
    var matched = 0;
    for (var i = 0; i < text.length && matched < q.length; i++) {
      if (text[i].toLowerCase() == q[matched]) {
        indices.add(i);
        matched++;
      }
    }
    return matched == q.length ? indices : null;
  }

  /// 按命中下标计算相关度得分（越大越相关）。
  static int scoreOf(List<int> indices) {
    if (indices.isEmpty) return 0;
    final consecutive = _consecutivePairs(indices);
    final gaps = indices.length - 1 - consecutive;
    final first = math.min(indices.first, 200);

    // 全连续即子串命中，给予最高分段。
    if (gaps == 0) return _exactBase + indices.length * 10 - first;

    final raw = _fuzzyBase + consecutive * 30 - first - gaps * 10;
    return raw.clamp(1, _fuzzyMax);
  }

  /// 相邻且下标连续的对数。
  static int _consecutivePairs(List<int> indices) {
    var count = 0;
    for (var i = 1; i < indices.length; i++) {
      if (indices[i] == indices[i - 1] + 1) count++;
    }
    return count;
  }
}