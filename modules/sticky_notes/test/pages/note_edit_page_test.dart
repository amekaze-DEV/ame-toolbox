import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:ametoolbox/shared/widgets/md3_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sticky_notes_module/features/sticky_notes/models/note_block.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_image_attachment.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_note.dart';
import 'package:sticky_notes_module/features/sticky_notes/pages/note_edit_page.dart';
import 'package:sticky_notes_module/features/sticky_notes/providers/sticky_notes_provider.dart';

import '../helpers/fake_device_info.dart';
import '../helpers/memory_storage_service.dart';

void main() {
  late MemoryStorageService storage;

  setUp(() {
    storage = MemoryStorageService();
  });

  List<Override> overrides() => [
        storageServiceProvider.overrideWithValue(storage),
        deviceInfoProvider.overrideWithValue(FakeDeviceInfoProvider()),
      ];

  Widget wrap(Widget child, {ProviderContainer? container}) {
    final scope = container == null
        ? ProviderScope(overrides: overrides(), child: child)
        : UncontrolledProviderScope(container: container, child: child);
    return InputModeScope(mode: InputMode.touch, child: scope);
  }

  testWidgets('新建页渲染标题输入、工具栏与保存按钮', (tester) async {
    await tester.pumpWidget(wrap(const MaterialApp(home: NoteEditPage())));
    await tester.pumpAndSettle();

    expect(find.text('新建便签'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
    expect(find.byTooltip('加粗'), findsOneWidget);
    expect(find.byTooltip('斜体'), findsOneWidget);
    expect(find.byTooltip('删除线'), findsOneWidget);
    expect(find.byTooltip('下划线'), findsOneWidget);
    expect(find.byTooltip('字号'), findsOneWidget);
    expect(find.byTooltip('字体颜色'), findsOneWidget);
    expect(find.byTooltip('插入图片'), findsOneWidget);
    // 已取消块类型与块级操作入口。
    expect(find.byTooltip('块格式'), findsNothing);
    expect(find.text('添加段落'), findsNothing);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('空标题点击保存提示错误且页面未退出', (tester) async {
    await tester.pumpWidget(wrap(const MaterialApp(home: NoteEditPage())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('请输入便签标题'), findsOneWidget);
    expect(find.text('新建便签'), findsOneWidget);
  });

  testWidgets('输入标题保存后新增便签', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      wrap(const MaterialApp(home: NoteEditPage()), container: container),
    );

    await tester.enterText(find.byType(TextField).first, '我的便签');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final notes = container.read(stickyNotesProvider).notes;
    expect(notes, hasLength(1));
    expect(notes.first.title, '我的便签');
  });

  testWidgets('正文输入后保存为段落块', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      wrap(const MaterialApp(home: NoteEditPage()), container: container),
    );

    await tester.enterText(find.byType(TextField).first, '正文便签');
    await tester.enterText(find.byType(TextField).at(1), '这是正文');
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final saved = container.read(stickyNotesProvider).notes.single;
    expect(saved.content, hasLength(1));
    expect(saved.content.first.inlines.first.text, '这是正文');
  });

  testWidgets('正文含图片块可保存并回读', (tester) async {
    final createdAt = DateTime(2026, 9, 1);
    final note = StickyNote(
      id: 'note_img_1',
      title: '带图便签',
      content: [
        const ParagraphBlock(inlines: [NoteInline(text: '正文')]),
        ImageBlock(
          attachment: NoteImageAttachment(
            id: 'img_1',
            dataBase64: 'AAAA',
            createdAt: createdAt,
          ),
        ),
      ],
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    await container.read(stickyNotesProvider).add(note);

    await tester.pumpWidget(
      wrap(MaterialApp(home: NoteEditPage(note: note)), container: container),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final saved = container.read(stickyNotesProvider).notes.single;
    expect(saved.content, hasLength(2));
    expect(saved.content[0], isA<ParagraphBlock>());
    expect(saved.content[1], isA<ImageBlock>());
    expect((saved.content[1] as ImageBlock).attachment.id, 'img_1');
  });

  testWidgets('编辑已有便签保存后更新标题并保留分类、id/createdAt 不变', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final created = DateTime(2026, 1, 1, 8);
    final note = StickyNote(
      id: 'note_edit_1',
      title: '原标题',
      content: const [
        ParagraphBlock(inlines: [NoteInline(text: '原正文')]),
      ],
      categoryId: 'life',
      createdAt: created,
      updatedAt: created,
    );
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    await container.read(stickyNotesProvider).add(note);

    await tester.pumpWidget(
      wrap(MaterialApp(home: NoteEditPage(note: note)), container: container),
    );
    await tester.pumpAndSettle();

    expect(find.text('编辑便签'), findsOneWidget);
    expect(find.text('原标题'), findsOneWidget);
    // 分类下拉预选当前分类「生活」。
    expect(find.text('生活'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, '新标题');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final saved = container.read(stickyNotesProvider).notes.single;
    expect(saved.title, '新标题');
    expect(saved.categoryId, 'life');
    expect(saved.id, 'note_edit_1');
    expect(saved.createdAt, created);
  });

  testWidgets('切换置顶开关保存后 isPinned 为 true 且 pinnedAt 非空', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      wrap(const MaterialApp(home: NoteEditPage()), container: container),
    );

    await tester.enterText(find.byType(TextField).first, '置顶便签');

    final switchFinder = find.descendant(
      of: find.byType(Md3Switch),
      matching: find.byType(Switch),
    );
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final saved = container.read(stickyNotesProvider).notes.single;
    expect(saved.isPinned, isTrue);
    expect(saved.pinnedAt, isNotNull);
  });
}