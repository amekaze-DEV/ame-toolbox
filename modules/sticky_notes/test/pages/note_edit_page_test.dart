import 'dart:typed_data';

import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/providers/file_provider.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';
import 'package:ametoolbox/shared/widgets/md3_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sticky_notes_module/features/sticky_notes/data/note_attachment_store.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_attachment.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_block.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_image_attachment.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_note.dart';
import 'package:sticky_notes_module/features/sticky_notes/pages/note_edit_page.dart';
import 'package:sticky_notes_module/features/sticky_notes/providers/sticky_notes_provider.dart';
import 'package:sticky_notes_module/features/sticky_notes/services/attachment_service.dart';

import '../helpers/fake_device_info.dart';
import '../helpers/fake_file_services.dart';
import '../helpers/memory_storage_service.dart';

void main() {
  late MemoryStorageService storage;
  late FakeFilePickerService picker;
  late FakeFileLauncherService launcher;

  setUp(() {
    storage = MemoryStorageService();
    picker = FakeFilePickerService();
    launcher = FakeFileLauncherService();
    attachmentBytesCache.clear();
  });

  List<Override> overrides() => [
        storageServiceProvider.overrideWithValue(storage),
        deviceInfoProvider.overrideWithValue(FakeDeviceInfoProvider()),
        filePickerProvider.overrideWithValue(picker),
        fileLauncherProvider.overrideWithValue(launcher),
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

  testWidgets('新建页无删除按钮，编辑页有删除按钮', (tester) async {
    final created = DateTime(2026, 1, 1, 8);
    final note = StickyNote(
      id: 'note_del_1',
      title: '待删便签',
      createdAt: created,
      updatedAt: created,
    );

    await tester.pumpWidget(wrap(const MaterialApp(home: NoteEditPage())));
    await tester.pumpAndSettle();
    expect(find.byTooltip('删除便签'), findsNothing);

    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    await container.read(stickyNotesProvider).add(note);

    await tester.pumpWidget(
      wrap(MaterialApp(home: NoteEditPage(note: note)), container: container),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('删除便签'), findsOneWidget);
  });

  testWidgets('编辑页删除便签：取消不删除，确认后移除并返回列表页', (tester) async {
    final created = DateTime(2026, 1, 1, 8);
    final note = StickyNote(
      id: 'note_del_2',
      title: '待删便签',
      createdAt: created,
      updatedAt: created,
    );
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    await container.read(stickyNotesProvider).add(note);

    await tester.pumpWidget(
      wrap(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NoteEditPage(note: note),
                  ),
                ),
                child: const Text('便签列表占位'),
              ),
            ),
          ),
        ),
        container: container,
      ),
    );

    await tester.tap(find.text('便签列表占位'));
    await tester.pumpAndSettle();
    expect(find.text('编辑便签'), findsOneWidget);

    // 取消：便签保留，仍停留在编辑页。
    await tester.tap(find.byTooltip('删除便签'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AdaptiveButton, '取消'));
    await tester.pumpAndSettle();
    expect(container.read(stickyNotesProvider).notes, hasLength(1));
    expect(find.text('编辑便签'), findsOneWidget);

    // 确认：便签移除并返回列表页。
    await tester.tap(find.byTooltip('删除便签'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AdaptiveButton, '删除'));
    await tester.pumpAndSettle();

    expect(container.read(stickyNotesProvider).notes, isEmpty);
    expect(find.text('编辑便签'), findsNothing);
    expect(find.text('便签列表占位'), findsOneWidget);
  });

  testWidgets('新建页展示附件区空态与添加入口', (tester) async {
    await tester.pumpWidget(wrap(const MaterialApp(home: NoteEditPage())));
    await tester.pumpAndSettle();

    expect(find.text('附件'), findsOneWidget);
    expect(find.text('添加附件'), findsOneWidget);
    expect(find.text('暂无附件，单个文件不超过 15MB'), findsOneWidget);
  });

  testWidgets('添加附件后展示文件名与大小，保存后元数据落库', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    picker.pickFileQueue.add(
      fakePickedFile(name: 'report.pdf', bytes: List.filled(2048, 1)),
    );

    await tester.pumpWidget(
      wrap(const MaterialApp(home: NoteEditPage()), container: container),
    );
    await tester.enterText(find.byType(TextField).first, '带附件便签');
    await tester.ensureVisible(find.text('添加附件'));
    await tester.tap(find.text('添加附件'));
    await tester.pumpAndSettle();

    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.text('2 KB'), findsOneWidget);
    expect(find.text('暂无附件，单个文件不超过 15MB'), findsNothing);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final saved = container.read(stickyNotesProvider).notes.single;
    expect(saved.attachments, hasLength(1));
    expect(saved.attachments.single.fileName, 'report.pdf');
    expect(saved.attachments.single.sizeBytes, 2048);
  });

  testWidgets('添加超过 15MB 的附件给出提示且不加入列表', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    picker.pickFileQueue.add(
      fakePickedFile(
        name: 'big.bin',
        bytes: [1],
        declaredSize: AttachmentService.kMaxAttachmentBytes + 1,
      ),
    );

    await tester.pumpWidget(wrap(const MaterialApp(home: NoteEditPage())));
    await tester.ensureVisible(find.text('添加附件'));
    await tester.tap(find.text('添加附件'));
    await tester.pumpAndSettle();

    expect(find.text('附件超过 15MB 上限，未添加'), findsOneWidget);
    expect(find.text('big.bin'), findsNothing);
  });

  testWidgets('删除附件需确认；保存后字节与元数据一并清理', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final created = DateTime(2026, 1, 1, 8);
    final attachment = NoteAttachment(
      id: 'att_old',
      fileName: 'old.pdf',
      sizeBytes: 3,
      createdAt: created,
    );
    final note = StickyNote(
      id: 'note_att_del',
      title: '带附件便签',
      attachments: [attachment],
      createdAt: created,
      updatedAt: created,
    );
    final store = NoteAttachmentStore(storageService: storage);
    await store.saveBytes('att_old', Uint8List.fromList([1, 2, 3]));

    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    await container.read(stickyNotesProvider).add(note);

    await tester.pumpWidget(
      wrap(MaterialApp(home: NoteEditPage(note: note)), container: container),
    );
    await tester.pumpAndSettle();
    expect(find.text('old.pdf'), findsOneWidget);

    // 取消：附件保留。
    await tester.tap(find.byTooltip('删除附件'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AdaptiveButton, '取消'));
    await tester.pumpAndSettle();
    expect(find.text('old.pdf'), findsOneWidget);

    // 确认：仅从列表移除，未保存前字节仍在。
    await tester.tap(find.byTooltip('删除附件'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AdaptiveButton, '删除'));
    await tester.pumpAndSettle();
    expect(find.text('old.pdf'), findsNothing);
    expect(await store.loadBytes('att_old'), isNotNull);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(
      container.read(stickyNotesProvider).notes.single.attachments,
      isEmpty,
    );
    expect(await store.loadBytes('att_old'), isNull);
  });

  testWidgets('附件可打开（系统默认查看器）与下载（另存为）', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    picker.pickFileQueue.add(fakePickedFile(name: 'x.txt', bytes: [5]));
    launcher.savePath = 'D:/out/x.txt';

    await tester.pumpWidget(wrap(const MaterialApp(home: NoteEditPage())));
    await tester.ensureVisible(find.text('添加附件'));
    await tester.tap(find.text('添加附件'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('打开附件'));
    await tester.pumpAndSettle();
    expect(launcher.openedFileNames, ['x.txt']);

    await tester.tap(find.byTooltip('下载附件'));
    await tester.pumpAndSettle();
    expect(launcher.savedFileNames, ['x.txt']);
    expect(find.text('已保存到 D:/out/x.txt'), findsOneWidget);
  });

  testWidgets('未保存离开编辑页时清理本次新增的附件字节', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    picker.pickFileQueue.add(fakePickedFile(name: 'temp.txt', bytes: [1]));
    final store = NoteAttachmentStore(storageService: storage);

    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      wrap(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const NoteEditPage()),
                ),
                child: const Text('便签列表占位'),
              ),
            ),
          ),
        ),
        container: container,
      ),
    );
    await tester.tap(find.text('便签列表占位'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('添加附件'));
    await tester.tap(find.text('添加附件'));
    await tester.pumpAndSettle();
    final id = attachmentBytesCache.keys.single;
    expect(await store.loadBytes(id), isNotNull);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('便签列表占位'), findsOneWidget);
    expect(await store.loadBytes(id), isNull);
  });
}