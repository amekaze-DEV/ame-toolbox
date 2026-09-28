import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_block.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_note.dart';
import 'package:sticky_notes_module/features/sticky_notes/pages/note_edit_page.dart';
import 'package:sticky_notes_module/features/sticky_notes/pages/sticky_notes_page.dart';
import 'package:sticky_notes_module/features/sticky_notes/providers/sticky_notes_provider.dart';

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

  Widget buildApp() => ProviderScope(
        overrides: overrides(),
        child: InputModeScope(
          mode: InputMode.touch,
          child: const MaterialApp(home: StickyNotesPage()),
        ),
      );

  Future<void> seed(List<StickyNote> notes) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    final controller = container.read(stickyNotesProvider);
    for (final note in notes) {
      await controller.add(note);
    }
  }

  testWidgets('空状态与顶栏', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('便签'), findsOneWidget);
    expect(find.byTooltip('新建便签'), findsOneWidget);
    expect(find.text('暂无便签'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
  });

  testWidgets('渲染便签标题、正文预览与置顶图标', (tester) async {
    await seed([
      buildNote('a', title: '购物清单', body: '牛奶与面包', isPinned: true),
      buildNote('b', title: '会议纪要'),
    ]);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('购物清单'), findsOneWidget);
    expect(find.text('会议纪要'), findsOneWidget);
    expect(find.text('牛奶与面包'), findsOneWidget);
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
  });

  testWidgets('分类筛选切换', (tester) async {
    await seed([
      buildNote('a', title: '工作任务', categoryId: 'work'),
      buildNote('b', title: '生活事项', categoryId: 'life'),
    ]);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
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

  testWidgets('长按菜单删除便签（确认）', (tester) async {
    await seed([buildNote('a', title: '待删除')]);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

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
    await seed([buildNote('a', title: '保留项')]);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.longPress(find.text('保留项'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('保留项'), findsOneWidget);
  });

  testWidgets('长按菜单置顶便签', (tester) async {
    await seed([buildNote('a', title: '置顶我')]);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.push_pin), findsNothing);

    await tester.longPress(find.text('置顶我'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('置顶'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.push_pin), findsOneWidget);
  });

  testWidgets('新建按钮进入编辑页', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('新建便签'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditPage), findsOneWidget);
  });
}
