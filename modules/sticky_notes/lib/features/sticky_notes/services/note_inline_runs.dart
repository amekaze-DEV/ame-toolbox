import 'dart:math';

import '../models/note_inline.dart';

/// 文本变更区间（由最长公共前缀 / 后缀定位）。
///
/// - [start]：变更起点（新文本中的下标）；
/// - [oldEnd]：旧文本中的变更终点（不含），旧文本按 `[start, oldEnd)` 删除；
/// - [inserted]：新插入的文本（可为空，表示纯删除）。
class TextDiff {
  const TextDiff({
    required this.start,
    required this.oldEnd,
    required this.inserted,
  });

  /// 变更起点。
  final int start;

  /// 旧文本变更终点（不含）。
  final int oldEnd;

  /// 新插入文本。
  final String inserted;

  /// 插入结束位置（新文本中的下标）。
  int get end => start + inserted.length;
}

/// 行内 runs 纯函数引擎。
///
/// 以 `List<NoteInline>` 作为「文本 + 样式」的唯一真源，把文本编辑与
/// 选区样式应用收敛为无副作用纯函数，便于单元测试。
abstract final class NoteInlineRuns {
  /// 拼接 runs 的纯文本。
  static String textOf(List<NoteInline> runs) =>
      runs.map((e) => e.text).join();

  /// 归一化 runs：丢弃空文本 run，合并样式全等的相邻 run。
  static List<NoteInline> normalize(List<NoteInline> runs) {
    final result = <NoteInline>[];
    for (final run in runs) {
      if (run.text.isEmpty) continue;
      if (result.isNotEmpty && _sameStyle(result.last, run)) {
        final last = result.removeLast();
        result.add(last.copyWith(text: last.text + run.text));
      } else {
        result.add(run);
      }
    }
    return result;
  }

  /// 取 [offset] 处的样式模板；空 runs 返回默认空 [NoteInline]。
  ///
  /// [offset] 落在两个 run 的边界时取左侧 run（偏移 0 取首个 run）。
  static NoteInline styleAtOffset(List<NoteInline> runs, int offset) {
    if (runs.isEmpty) return const NoteInline(text: '');
    final index = _runIndexAt(runs, offset);
    return runs[index];
  }

  /// 在 `[start, end)` 区间套用 [template] 的样式位。
  ///
  /// - `start == end`（折叠光标）时作用于光标所在 run；
  /// - runs 为空时原样返回（空块样式由控制器以 pendingStyle 处理）。
  static List<NoteInline> applyStyleToRange(
    List<NoteInline> runs,
    int start,
    int end,
    NoteInline template,
  ) {
    if (runs.isEmpty) return runs;
    final total = textOf(runs).length;
    var s = start.clamp(0, total);
    var e = end.clamp(0, total);
    if (s > e) {
      final swap = s;
      s = e;
      e = swap;
    }

    if (s == e) {
      final index = _runIndexAt(runs, s);
      final result = List<NoteInline>.of(runs);
      result[index] = overrideStyle(result[index], template);
      return normalize(result);
    }

    final left = <NoteInline>[];
    final right = <NoteInline>[];
    var cursor = 0;
    for (final run in runs) {
      final rs = cursor;
      final re = cursor + run.text.length;
      cursor = re;
      final leftEnd = min(re, s);
      if (leftEnd > rs) {
        left.add(run.copyWith(text: run.text.substring(0, leftEnd - rs)));
      }
      final rightStart = max(rs, e);
      if (re > rightStart) {
        right.add(run.copyWith(text: run.text.substring(rightStart - rs)));
      }
    }

    final covered = textOf(runs).substring(s, e);
    final middle = <NoteInline>[
      overrideStyle(NoteInline(text: covered), template),
    ];
    return normalize([...left, ...middle, ...right]);
  }

  /// 定位 `oldText` → `newText` 的变更区间（最长公共前缀 / 后缀，互不重叠）。
  static TextDiff diffOf(String oldText, String newText) {
    final maxPrefix = min(oldText.length, newText.length);
    var prefix = 0;
    while (prefix < maxPrefix &&
        oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
      prefix++;
    }
    final maxSuffix = min(oldText.length, newText.length) - prefix;
    var suffix = 0;
    while (suffix < maxSuffix &&
        oldText.codeUnitAt(oldText.length - 1 - suffix) ==
            newText.codeUnitAt(newText.length - 1 - suffix)) {
      suffix++;
    }
    return TextDiff(
      start: prefix,
      oldEnd: oldText.length - suffix,
      inserted: newText.substring(prefix, newText.length - suffix),
    );
  }

  /// 按文本变更（`oldText` → `newText`）重建 runs，保留未受影响部分的样式。
  ///
  /// 新插入文本默认继承变更起点处的原有样式；传入 [insertedTemplate] 时
  /// 改用该模板（用于「折叠光标下设定样式，仅影响后续输入」）。
  static List<NoteInline> replaceTextRange(
    List<NoteInline> runs,
    String oldText,
    String newText, {
    NoteInline? insertedTemplate,
  }) {
    if (oldText == newText) return runs;

    final diff = diffOf(oldText, newText);
    final a = diff.start;
    final bOld = diff.oldEnd;
    final inserted = diff.inserted;

    final template = insertedTemplate ?? styleAtOffset(runs, a);
    final left = <NoteInline>[];
    final right = <NoteInline>[];
    var cursor = 0;
    for (final run in runs) {
      final rs = cursor;
      final re = cursor + run.text.length;
      cursor = re;
      final leftEnd = min(re, a);
      if (leftEnd > rs) {
        left.add(run.copyWith(text: run.text.substring(0, leftEnd - rs)));
      }
      final rightStart = max(rs, bOld);
      if (re > rightStart) {
        right.add(run.copyWith(text: run.text.substring(rightStart - rs)));
      }
    }

    final middle = inserted.isEmpty
        ? const <NoteInline>[]
        : <NoteInline>[overrideStyle(NoteInline(text: inserted), template)];

    return normalize([...left, ...middle, ...right]);
  }

  /// 覆盖 run 的样式位为 [template]（不改动文本，不改动 link）。
  static NoteInline overrideStyle(NoteInline run, NoteInline template) =>
      run.copyWith(
        bold: template.bold,
        italic: template.italic,
        underline: template.underline,
        strikethrough: template.strikethrough,
        fontSize: template.fontSize,
        clearFontSize: template.fontSize == null,
        colorValue: template.colorValue,
        clearColorValue: template.colorValue == null,
      );

  /// 对全部 runs 覆盖样式位（空块 pendingStyle 播种用）。
  static List<NoteInline> overrideStyleAll(
    List<NoteInline> runs,
    NoteInline template,
  ) =>
      normalize([for (final run in runs) overrideStyle(run, template)]);

  /// 样式位是否全等（用于相邻 run 合并）。
  static bool _sameStyle(NoteInline a, NoteInline b) =>
      a.bold == b.bold &&
      a.italic == b.italic &&
      a.underline == b.underline &&
      a.strikethrough == b.strikethrough &&
      a.fontSize == b.fontSize &&
      a.colorValue == b.colorValue &&
      a.link == b.link;

  /// 定位 [offset] 所在的 run 下标（边界取左侧 run）。
  static int _runIndexAt(List<NoteInline> runs, int offset) {
    var cursor = 0;
    for (var i = 0; i < runs.length; i++) {
      final end = cursor + runs[i].text.length;
      if (offset <= end) return i;
      cursor = end;
    }
    return runs.length - 1;
  }
}