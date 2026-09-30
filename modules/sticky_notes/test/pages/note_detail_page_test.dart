import 'dart:typed_data';

import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/providers/file_provider.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/data/note_attachment_store.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_attachment.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_block.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_inline.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_note.dart';
import 'package:sticky_notes_module/features/sticky_notes/pages/note_detail_page.dart';
import 'package:sticky_notes_module/features/sticky_notes/pages/note_edit_page.dart';
import 'package:sticky_notes_module/features/sticky_notes/widgets/note_detail_view.dart';
import 'package:sticky_notes_module/features/sticky_notes/providers/sticky_notes_provider.dart';

import '../helpers/fake_device_info.dart';
import '../helpers/fake_file_services.dart';
import '../helpers/rich_text_spans.dart';
import '../helpers/memory_storage_service.dart';

void main() {
  late MemoryStorageService storage;
  final createdAt = DateTime(2026, 9, 1, 9);

  final note = StickyNote(
    id: 'note_view_1',
    title: '查看标题',
    content: const [
      ParagraphBlock(
        inlines: [
          NoteInline(text: '普通'),
          NoteInline(text: '加粗', bold: true),
          NoteInline(text: '大字', fontSize: 26),
          NoteInline(text: '红字', colorValue: 0xFFED7D31),
        ],
      ),
    ],
    categoryId: 'work',
    isPinned: true,
    pinnedAt: createdAt,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  late FakeFileLauncherService launcher;

  setUp(() {
    storage = MemoryStorageService();
    launcher = FakeFileLauncherService();
    attachmentBytesCache.clear();
  });

  List<Override> overrides() => [
        storageServiceProvider.overrideWithValue(storage),
        deviceInfoProvider.overrideWithValue(FakeDeviceInfoProvider()),
        fileLauncherProvider.overrideWithValue(launcher),
      ];

  Future<ProviderContainer> pumpDetail(
    WidgetTester tester, {
    StickyNote? target,
  }) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    await container.read(stickyNotesProvider).add(target ?? note);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: InputModeScope(
          mode: InputMode.touch,
          child: MaterialApp(home: NoteDetailPage(noteId: note.id)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('只读展示标题、分类与正文样式', (tester) async {
    await pumpDetail(tester);

    expect(find.text('便签详情'), findsOneWidget);
    expect(find.text('查看标题'), findsOneWidget);
    expect(find.text('工作'), findsOneWidget);
    expect(find.byIcon(Icons.push_pin), findsOneWidget);

    // 正文按行内样式渲染，且不存在任何编辑输入框。
    expect(find.textContaining('普通'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    final span = runsSpanIn(tester, find.byType(NoteDetailView), contains: '普通');
    expect(span.children!.length, 4);
    expect(
      (span.children![1] as TextSpan).style!.fontWeight,
      FontWeight.bold,
    );
    expect((span.children![2] as TextSpan).style!.fontSize, 26);
    expect(
      (span.children![3] as TextSpan).style!.color,
      const Color(0xFFED7D31),
    );
  });

  testWidgets('顶栏编辑入口进入编辑页', (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditPage), findsOneWidget);
    expect(find.text('编辑便签'), findsOneWidget);
    expect(find.text('查看标题'), findsWidgets);
  });

  testWidgets('编辑返回后查看页内容刷新', (tester) async {
    final container = await pumpDetail(tester);

    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '改后标题');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(container.read(stickyNotesProvider).notes.single.title, '改后标题');
    expect(find.byType(NoteDetailPage), findsOneWidget);
    expect(find.text('改后标题'), findsOneWidget);
  });

  testWidgets('便签不存在时展示占位提示', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: InputModeScope(
          mode: InputMode.touch,
          child: const MaterialApp(home: NoteDetailPage(noteId: 'missing')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('该便签已被删除'), findsOneWidget);
    expect(find.text('编辑'), findsNothing);
  });

  testWidgets('空正文展示占位文案', (tester) async {
    final emptyNote = StickyNote(
      id: 'note_view_1',
      title: '空正文',
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    await pumpDetail(tester, target: emptyNote);

    expect(find.text('暂无正文'), findsOneWidget);
  });

  testWidgets('无附件时不展示附件区', (tester) async {
    await pumpDetail(tester);

    expect(find.text('附件'), findsNothing);
  });

  testWidgets('附件区展示文件名与大小，可打开与下载', (tester) async {
    final attachment = NoteAttachment(
      id: 'att_view',
      fileName: '明细.xlsx',
      sizeBytes: 3072,
      createdAt: createdAt,
    );
    final withAttachment = StickyNote(
      id: 'note_view_1',
      title: '带附件便签',
      attachments: [attachment],
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final store = NoteAttachmentStore(storageService: storage);
    await store.saveBytes('att_view', Uint8List.fromList([1, 2, 3]));
    launcher.savePath = 'D:/out/明细.xlsx';

    await pumpDetail(tester, target: withAttachment);

    expect(find.text('附件'), findsOneWidget);
    expect(find.text('明细.xlsx'), findsOneWidget);
    expect(find.text('3 KB'), findsOneWidget);
    // 只读页不提供删除入口。
    expect(find.byTooltip('删除附件'), findsNothing);

    await tester.tap(find.byTooltip('打开附件'));
    await tester.pumpAndSettle();
    expect(launcher.openedFileNames, ['明细.xlsx']);

    await tester.tap(find.byTooltip('下载附件'));
    await tester.pumpAndSettle();
    expect(find.text('已保存到 D:/out/明细.xlsx'), findsOneWidget);
  });

  testWidgets('打开失败时提示且页面不崩溃', (tester) async {
    final attachment = NoteAttachment(
      id: 'att_fail',
      fileName: 'broken.bin',
      sizeBytes: 1,
      createdAt: createdAt,
    );
    final withAttachment = StickyNote(
      id: 'note_view_1',
      title: '损坏附件',
      attachments: [attachment],
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    launcher.failOnOpen = true;
    await pumpDetail(tester, target: withAttachment);

    await tester.tap(find.byTooltip('打开附件'));
    await tester.pumpAndSettle();

    expect(find.text('打开「broken.bin」失败'), findsOneWidget);
    expect(find.text('损坏附件'), findsOneWidget);
  });
}