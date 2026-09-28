import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';
import 'package:sticky_notes_module/features/sticky_notes/services/note_inline_runs.dart';

void main() {
  group('NoteInlineRuns.textOf', () {
    test('按顺序拼接 runs 文本', () {
      expect(
        NoteInlineRuns.textOf(const [NoteInline(text: 'ab'), NoteInline(text: 'c')]),
        'abc',
      );
      expect(NoteInlineRuns.textOf(const []), '');
    });
  });

  group('NoteInlineRuns.normalize', () {
    test('丢弃空文本 run 并合并样式全等的相邻 run', () {
      const runs = [
        NoteInline(text: 'a'),
        NoteInline(text: ''),
        NoteInline(text: 'b'),
        NoteInline(text: 'c', bold: true),
        NoteInline(text: 'd', bold: true),
      ];
      final result = NoteInlineRuns.normalize(runs);
      expect(result.length, 2);
      expect(result[0].text, 'ab');
      expect(result[0].bold, false);
      expect(result[1].text, 'cd');
      expect(result[1].bold, true);
    });

    test('样式不同不合并', () {
      final result = NoteInlineRuns.normalize(const [
        NoteInline(text: 'a'),
        NoteInline(text: 'b', colorValue: 0xFFED7D31),
      ]);
      expect(result.length, 2);
    });
  });

  group('NoteInlineRuns.styleAtOffset', () {
    const runs = [NoteInline(text: 'ab'), NoteInline(text: 'cd', bold: true)];

    test('空 runs 返回默认空行内元素', () {
      expect(NoteInlineRuns.styleAtOffset(const [], 3).text, '');
      expect(NoteInlineRuns.styleAtOffset(const [], 3).bold, false);
    });

    test('边界取左侧 run，越界取末个 run', () {
      expect(NoteInlineRuns.styleAtOffset(runs, 0).bold, false);
      expect(NoteInlineRuns.styleAtOffset(runs, 2).bold, false);
      expect(NoteInlineRuns.styleAtOffset(runs, 3).bold, true);
      expect(NoteInlineRuns.styleAtOffset(runs, 99).bold, true);
    });
  });

  group('NoteInlineRuns.applyStyleToRange', () {
    test('区间中间切分，仅选中片段套用样式', () {
      final runs = NoteInlineRuns.applyStyleToRange(
        const [NoteInline(text: 'abcd')],
        1,
        3,
        const NoteInline(text: '', bold: true),
      );
      expect(runs.length, 3);
      expect(runs[0].text, 'a');
      expect(runs[0].bold, false);
      expect(runs[1].text, 'bc');
      expect(runs[1].bold, true);
      expect(runs[2].text, 'd');
      expect(runs[2].bold, false);
    });

    test('跨多个 run 的选区统一套用样式', () {
      final runs = NoteInlineRuns.applyStyleToRange(
        const [NoteInline(text: 'ab'), NoteInline(text: 'cd')],
        1,
        3,
        const NoteInline(text: '', underline: true),
      );
      expect(NoteInlineRuns.textOf(runs), 'abcd');
      expect(runs.length, 3);
      expect(runs[0].text, 'a');
      expect(runs[0].underline, false);
      expect(runs[1].text, 'bc');
      expect(runs[1].underline, true);
      expect(runs[2].text, 'd');
      expect(runs[2].underline, false);
    });

    test('折叠光标作用于光标所在 run', () {
      final runs = NoteInlineRuns.applyStyleToRange(
        const [NoteInline(text: 'ab'), NoteInline(text: 'cd')],
        1,
        1,
        const NoteInline(text: '', underline: true),
      );
      expect(runs[0].underline, true);
      expect(runs[1].underline, false);
    });

    test('clear 标志可清除字号与颜色', () {
      final runs = NoteInlineRuns.applyStyleToRange(
        const [
          NoteInline(
            text: 'ab',
            fontSize: 36,
            colorValue: 0xFFED7D31,
          ),
        ],
        0,
        2,
        const NoteInline(text: ''),
      );
      expect(runs.single.fontSize, isNull);
      expect(runs.single.colorValue, isNull);
    });

    test('空 runs 原样返回', () {
      const runs = <NoteInline>[];
      expect(
        NoteInlineRuns.applyStyleToRange(
          runs,
          0,
          0,
          const NoteInline(text: '', italic: true),
        ),
        same(runs),
      );
    });
  });

  group('NoteInlineRuns.replaceTextRange', () {
    test('末尾追加继承原样式', () {
      final runs = NoteInlineRuns.replaceTextRange(
        const [NoteInline(text: 'ab', bold: true)],
        'ab',
        'abc',
      );
      expect(runs.single.text, 'abc');
      expect(runs.single.bold, true);
    });

    test('中间删除保留两侧样式', () {
      final runs = NoteInlineRuns.replaceTextRange(
        const [NoteInline(text: 'ab'), NoteInline(text: 'cd', bold: true)],
        'abcd',
        'ad',
      );
      expect(NoteInlineRuns.textOf(runs), 'ad');
      expect(runs[0].bold, false);
      expect(runs[1].bold, true);
    });

    test('中段替换继承左侧样式', () {
      final runs = NoteInlineRuns.replaceTextRange(
        const [NoteInline(text: 'abcd', italic: true)],
        'abcd',
        'axcd',
      );
      expect(NoteInlineRuns.textOf(runs), 'axcd');
      expect(runs.every((e) => e.italic), true);
    });

    test('空 runs 输入文本生成默认样式 run', () {
      final runs = NoteInlineRuns.replaceTextRange(const [], '', 'abc');
      expect(runs.single.text, 'abc');
      expect(runs.single.hasInlineStyle, false);
    });

    test('文本未变化时原样返回', () {
      const runs = [NoteInline(text: 'ab')];
      expect(NoteInlineRuns.replaceTextRange(runs, 'ab', 'ab'), same(runs));
    });
  });

  group('NoteInlineRuns.overrideStyleAll', () {
    test('全部 run 套用模板样式并归一化', () {
      final runs = NoteInlineRuns.overrideStyleAll(
        const [NoteInline(text: 'a'), NoteInline(text: 'b')],
        const NoteInline(text: '', bold: true),
      );
      expect(runs.length, 1);
      expect(runs.single.text, 'ab');
      expect(runs.single.bold, true);
    });
  });
}