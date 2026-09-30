import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/models/layout_mode.dart';
import 'package:ametoolbox/core/providers/layout_provider.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_block.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_note.dart';
import 'package:sticky_notes_module/features/sticky_notes/pages/note_detail_page.dart';
import 'package:sticky_notes_module/features/sticky_notes/pages/note_edit_page.dart';
import 'package:sticky_notes_module/features/sticky_notes/pages/sticky_notes_page.dart';
import 'package:sticky_notes_module/features/sticky_notes/providers/sticky_notes_provider.dart';
import 'package:sticky_notes_module/features/sticky_notes/widgets/note_detail_view.dart';

import '../helpers/fake_device_info.dart';
import '../helpers/memory_storage_service.dart';

void main() {
  late MemoryStorageService storage;
  final base = DateTime(2026, 9, 1, 9);

  StickyNote buildNote(
    String id, {
    String? title,
    String? categoryId,
    bool isPinned = false,
    String? body,
  }) =>
      StickyNote(
        id: id,
        title: title ?? id,
        content: body == null
            ? const []
            : [
                ParagraphBlock(inlines: [NoteInline(text: body)]),
              ],
        categoryId: categoryId,
        isPinned: isPinned,
        pinnedAt: isPinned ? base : null,
        createdAt: base,
        updatedAt: base,
      );

  setUp(() {
    storage = MemoryStorageService();
  });

  List<Override> overrides() => [
        storageServiceProvider.overrideWithValue(storage),
        deviceInfoProvider.overrideWithValue(FakeDeviceInfoProvider()),
      ];

  /// 注入数据并按指定布局模式渲染主页。
  ///
  /// 说明：[LayoutController] 读取 `PlatformDispatcher.instance`（测试环境下固定
  /// 800x600，宽高比 ≈ 1.33），无法通过 `tester.view` 改变；这里改用其公开的
  /// 断点 API 控制判定结果（比例 1.33 ≥ 1.0 → 横屏；< 2.0 → 竖屏）。
  Future<ProviderContainer> pumpPage(
    WidgetTester tester, {
    required LayoutMode mode,
    List<StickyNote> notes = const [],
  }) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    final notesController = container.read(stickyNotesProvider);
    for (final note in notes) {
      await notesController.add(note);
    }
    final layout = container.read(layoutControllerProvider);
    await layout.setAutoBreakpoint(false);
    await layout.setBreakpoint(
      mode == LayoutMode.landscape ? 1.0 : 2.0,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: InputModeScope(
          mode: InputMode.touch,
          child: const MaterialApp(home: StickyNotesPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('空状态与顶栏', (tester) async {
    await pumpPage(tester, mode: LayoutMode.portrait);

    expect(find.text('便签'), findsOneWidget);
    expect(find.byTooltip('新建便签'), findsOneWidget);
    expect(find.text('暂无便签'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
  });

  testWidgets('竖屏渲染便签标题、正文预览与置顶图标', (tester) async {
    await pumpPage(
      tester,
      mode: LayoutMode.portrait,
      notes: [
        buildNote('a', title: '购物清单', body: '牛奶与面包', isPinned: true),
        buildNote('b', title: '会议纪要'),
      ],
    );

    expect(find.text('购物清单'), findsOneWidget);
    expect(find.text('会议纪要'), findsOneWidget);
    expect(find.text('牛奶与面包'), findsOneWidget);
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
    // 竖屏不展示预览区。
    expect(find.byType(NoteDetailView), findsNothing);
  });

  testWidgets('竖屏点击便签进入查看页，查看页提供编辑入口', (tester) async {
    await pumpPage(
      tester,
      mode: LayoutMode.portrait,
      notes: [buildNote('a', title: '查看我', body: '正文内容')],
    );

    await tester.tap(find.text('查看我'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteDetailPage), findsOneWidget);
    expect(find.text('便签详情'), findsOneWidget);
    expect(find.text('正文内容'), findsOneWidget);
    // 查看页本身不含编辑输入框。
    expect(find.byType(NoteEditPage), findsNothing);

    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditPage), findsOneWidget);
  });

  testWidgets('分类筛选切换', (tester) async {
    await pumpPage(
      tester,
      mode: LayoutMode.portrait,
      notes: [
        buildNote('a', title: '工作任务', categoryId: 'work'),
        buildNote('b', title: '生活事项', categoryId: 'life'),
      ],
    );

    expect(find.text('工作任务'), findsOneWidget);
    expect(find.text('生活事项'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '工作'));
    await tester.pumpAndSettle();
    expect(find.text('工作任务'), findsOneWidget);
    expect(find.text('生活事项'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
    await tester.pumpAndSettle();
    expect(find.text('生活事项'), findsOneWidget);
  });

  testWidgets('横屏：列表 + 预览双栏直接查看内容', (tester) async {
    await pumpPage(
      tester,
      mode: LayoutMode.landscape,
      notes: [
        buildNote('a', title: '甲', body: '甲正文'),
        buildNote('b', title: '乙', body: '乙正文'),
      ],
    );

    // 右侧预览区默认展示列表首项内容。
    expect(find.byType(NoteDetailView), findsOneWidget);
    expect(find.text('内容查看'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NoteDetailView),
        matching: find.text('甲正文'),
      ),
      findsOneWidget,
    );

    // 点击另一便签直接切换预览内容，不跳转页面。
    await tester.tap(find.text('乙').first);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(NoteDetailView),
        matching: find.text('乙正文'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(NoteDetailView),
        matching: find.text('甲正文'),
      ),
      findsNothing,
    );
    expect(find.byType(NoteDetailPage), findsNothing);
  });

  testWidgets('横屏：预览区编辑入口进入编辑页', (tester) async {
    await pumpPage(
      tester,
      mode: LayoutMode.landscape,
      notes: [buildNote('a', title: '甲', body: '甲正文')],
    );

    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditPage), findsOneWidget);
    expect(find.text('编辑便签'), findsOneWidget);
  });

  testWidgets('长按菜单删除便签（确认）', (tester) async {
    await pumpPage(
      tester,
      mode: LayoutMode.portrait,
      notes: [buildNote('a', title: '待删除')],
    );

    await tester.longPress(find.text('待删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除'), findsOneWidget);

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除便签'), findsOneWidget);

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('待删除'), findsNothing);
    expect(find.text('暂无便签'), findsOneWidget);
  });

  testWidgets('删除确认取消后便签保留', (tester) async {
    await pumpPage(
      tester,
      mode: LayoutMode.portrait,
      notes: [buildNote('a', title: '保留项')],
    );

    await tester.longPress(find.text('保留项'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('保留项'), findsOneWidget);
  });

  testWidgets('长按菜单置顶便签', (tester) async {
    await pumpPage(
      tester,
      mode: LayoutMode.portrait,
      notes: [buildNote('a', title: '置顶我')],
    );
    expect(find.byIcon(Icons.push_pin), findsNothing);

    await tester.longPress(find.text('置顶我'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('置顶'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.push_pin), findsOneWidget);
  });

  testWidgets('长按菜单编辑进入编辑页', (tester) async {
    await pumpPage(
      tester,
      mode: LayoutMode.portrait,
      notes: [buildNote('a', title: '编辑我')],
    );

    await tester.longPress(find.text('编辑我'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditPage), findsOneWidget);
  });

  testWidgets('新建按钮进入编辑页', (tester) async {
    await pumpPage(tester, mode: LayoutMode.portrait);

    await tester.tap(find.byTooltip('新建便签'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditPage), findsOneWidget);
  });

  testWidgets('顶栏搜索：模糊关键字过滤标题与正文', (tester) async {
    await pumpPage(
      tester,
      mode: LayoutMode.portrait,
      notes: [
        buildNote('a', title: '工作汇报'),
        buildNote('b', title: '购物清单'),
        buildNote('c', title: '无关标题', body: '会议纪要'),
      ],
    );

    await tester.tap(find.byTooltip('搜索便签'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('退出搜索'), findsOneWidget);

    // 模糊：跳过中间字符命中「工作汇报」。
    await tester.enterText(find.byType(TextField), '工报');
    await tester.pumpAndSettle();
    expect(find.text('工作汇报'), findsOneWidget);
    expect(find.text('购物清单'), findsNothing);
    expect(find.text('无关标题'), findsNothing);

    // 正文命中。
    await tester.enterText(find.byType(TextField), '会议');
    await tester.pumpAndSettle();
    expect(find.text('无关标题'), findsOneWidget);
    expect(find.text('工作汇报'), findsNothing);
  });

  testWidgets('顶栏搜索：未命中展示提示，清空后恢复列表', (tester) async {
    await pumpPage(
      tester,
      mode: LayoutMode.portrait,
      notes: [buildNote('a', title: '工作汇报')],
    );

    await tester.tap(find.byTooltip('搜索便签'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '不存在的词');
    await tester.pumpAndSettle();
    expect(find.text('未找到匹配的便签'), findsOneWidget);

    await tester.tap(find.byTooltip('清空关键字'));
    await tester.pumpAndSettle();
    expect(find.text('工作汇报'), findsOneWidget);
    expect(find.text('未找到匹配的便签'), findsNothing);
  });

  testWidgets('顶栏搜索：退出检索恢复完整列表与常规顶栏', (tester) async {
    await pumpPage(
      tester,
      mode: LayoutMode.portrait,
      notes: [
        buildNote('a', title: '工作汇报'),
        buildNote('b', title: '购物清单'),
      ],
    );

    await tester.tap(find.byTooltip('搜索便签'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '工作');
    await tester.pumpAndSettle();
    expect(find.text('购物清单'), findsNothing);

    await tester.tap(find.byTooltip('退出搜索'));
    await tester.pumpAndSettle();

    expect(find.text('便签'), findsOneWidget);
    expect(find.byTooltip('搜索便签'), findsOneWidget);
    expect(find.text('购物清单'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('搜索与分类筛选叠加', (tester) async {
    await pumpPage(
      tester,
      mode: LayoutMode.portrait,
      notes: [
        buildNote('w', title: '会议纪要', categoryId: 'work'),
        buildNote('l', title: '会议记录', categoryId: 'life'),
      ],
    );

    await tester.tap(find.byTooltip('搜索便签'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '会议');
    await tester.pumpAndSettle();
    expect(find.text('会议纪要'), findsOneWidget);
    expect(find.text('会议记录'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '工作'));
    await tester.pumpAndSettle();
    expect(find.text('会议纪要'), findsOneWidget);
    expect(find.text('会议记录'), findsNothing);
  });

  testWidgets('横屏搜索：列表过滤且预览区同步切换', (tester) async {
    await pumpPage(
      tester,
      mode: LayoutMode.landscape,
      notes: [
        buildNote('a', title: '会议纪要', body: '甲正文'),
        buildNote('b', title: '购物清单', body: '乙正文'),
      ],
    );

    await tester.tap(find.byTooltip('搜索便签'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '会议');
    await tester.pumpAndSettle();

    expect(find.text('购物清单'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(NoteDetailView),
        matching: find.text('甲正文'),
      ),
      findsOneWidget,
    );
  });
}