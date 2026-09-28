import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_sort_mode.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/sticky_note.dart';
import 'package:sticky_notes_module/features/sticky_notes/pages/sticky_notes_settings_page.dart';
import 'package:sticky_notes_module/features/sticky_notes/providers/sticky_notes_config_provider.dart';
import 'package:sticky_notes_module/features/sticky_notes/providers/sticky_notes_config_repository_provider.dart';
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

  Widget buildApp() {
    return ProviderScope(
      overrides: overrides(),
      child: InputModeScope(
        mode: InputMode.touch,
        child: const MaterialApp(home: StickyNotesSettingsPage()),
      ),
    );
  }

  Widget buildWithContainer(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: InputModeScope(
        mode: InputMode.touch,
        child: const MaterialApp(home: StickyNotesSettingsPage()),
      ),
    );
  }

  testWidgets('设置页渲染默认排序三选项与分类管理标题', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('默认排序'), findsOneWidget);
    expect(find.text('按更新时间'), findsOneWidget);
    expect(find.text('按创建时间'), findsOneWidget);
    expect(find.text('按标题'), findsOneWidget);
    expect(find.text('分类管理'), findsOneWidget);

    // 内置分类默认展示
    expect(find.text('工作'), findsOneWidget);
    expect(find.text('生活'), findsOneWidget);
    expect(find.text('其他'), findsOneWidget);
  });

  testWidgets('点击「按标题」更新默认排序并写入存储', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(buildWithContainer(container));
    await tester.pumpAndSettle();

    expect(
      container.read(stickyNotesConfigProvider).config.defaultSortMode,
      NoteSortMode.updatedDesc,
    );

    await tester.tap(find.text('按标题'));
    await tester.pumpAndSettle();

    expect(
      container.read(stickyNotesConfigProvider).config.defaultSortMode,
      NoteSortMode.titleAsc,
    );
    final stored = await container.read(stickyNotesConfigRepositoryProvider).load();
    expect(stored.defaultSortMode, NoteSortMode.titleAsc);
  });

  testWidgets('新增分类：输入名称确认后分类数 +1 且 id 以 category_ 开头', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(buildWithContainer(container));
    await tester.pumpAndSettle();
    expect(
      container.read(stickyNotesConfigProvider).config.categories.length,
      3,
    );

    await tester.tap(find.text('新增分类'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '灵感');
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    final categories =
        container.read(stickyNotesConfigProvider).config.categories;
    expect(categories.length, 4);
    expect(categories.last.name, '灵感');
    expect(categories.last.id.startsWith('category_'), isTrue);
    expect(find.text('灵感'), findsOneWidget);
  });

  testWidgets('内置分类行不显示删除按钮', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byTooltip('删除分类'), findsNothing);
    expect(find.byTooltip('编辑分类'), findsNWidgets(3));
  });

  testWidgets('删除自定义分类后该分类便签 categoryId 置空', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(buildWithContainer(container));
    await tester.pumpAndSettle();

    final configController = container.read(stickyNotesConfigProvider);
    await configController.addCategory('项目', colorValue: 0xFF00897B);
    await tester.pumpAndSettle();
    final customId = configController.config.categories.last.id;

    final now = DateTime(2026, 1, 1);
    final notesController = container.read(stickyNotesProvider);
    await notesController.add(
      StickyNote(
        id: 'n1',
        title: '关联便签',
        categoryId: customId,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('删除分类'), findsOneWidget);
    await tester.tap(find.byTooltip('删除分类'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(
      container.read(stickyNotesConfigProvider).config.categories.length,
      3,
    );
    expect(
      container.read(stickyNotesProvider).notes.single.categoryId,
      isNull,
    );
  });
}