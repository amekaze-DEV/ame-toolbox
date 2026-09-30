import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';
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

  /// 分类对话框内的圆形候选色块。
  Finder colorSwatches() => find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle &&
            (widget.decoration! as BoxDecoration).color != null,
      );

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

  testWidgets('默认分类行同样提供删除与编辑入口', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byTooltip('删除分类'), findsNWidgets(3));
    expect(find.byTooltip('编辑分类'), findsNWidgets(3));
  });

  testWidgets('新增分类对话框展示 18 色预设色板并可选用', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(buildWithContainer(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新增分类'));
    await tester.pumpAndSettle();

    Finder swatches() => find.descendant(
          of: find.byType(AlertDialog),
          matching: colorSwatches(),
        );
    expect(swatches(), findsNWidgets(18));

    await tester.tap(swatches().last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '灰色分类');
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(
      container
          .read(stickyNotesConfigProvider)
          .config
          .categories
          .last
          .colorValue,
      0xFF424242,
    );
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

    // 3 个默认分类 + 1 个自定义分类均提供删除入口。
    expect(find.byTooltip('删除分类'), findsNWidgets(4));
    await tester.tap(find.byTooltip('删除分类').last);
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

  testWidgets('编辑对话框：默认与自定义分类均提供删除按钮，新增对话框不提供', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(buildWithContainer(container));
    await tester.pumpAndSettle();
    await container
        .read(stickyNotesConfigProvider)
        .addCategory('临时', colorValue: 0xFF6A1B9A);
    await tester.pumpAndSettle();

    // 默认分类（工作）的编辑对话框提供删除入口。
    await tester.tap(find.byTooltip('编辑分类').first);
    await tester.pumpAndSettle();
    expect(find.text('编辑分类'), findsOneWidget);
    expect(find.widgetWithText(AdaptiveButton, '删除'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    // 自定义分类（临时）的编辑对话框同样提供删除入口。
    await tester.tap(find.byTooltip('编辑分类').last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AdaptiveButton, '删除'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    // 新增分类对话框无删除入口。
    await tester.tap(find.text('新增分类'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AdaptiveButton, '删除'), findsNothing);
  });

  testWidgets('编辑对话框内删除分类：确认后分类移除且关联便签置空', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(buildWithContainer(container));
    await tester.pumpAndSettle();

    final configController = container.read(stickyNotesConfigProvider);
    await configController.addCategory('项目', colorValue: 0xFF00897B);
    await tester.pumpAndSettle();
    final customId = configController.config.categories.last.id;

    final now = DateTime(2026, 1, 1);
    await container.read(stickyNotesProvider).add(
          StickyNote(
            id: 'n1',
            title: '关联便签',
            categoryId: customId,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('编辑分类').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AdaptiveButton, '删除'));
    await tester.pumpAndSettle();
    // 弹出删除确认对话框。
    expect(find.text('删除分类'), findsOneWidget);

    await tester.tap(find.widgetWithText(AdaptiveButton, '删除').last);
    await tester.pumpAndSettle();

    expect(
      container.read(stickyNotesConfigProvider).config.categories.length,
      3,
    );
    expect(
      container.read(stickyNotesProvider).notes.single.categoryId,
      isNull,
    );
    // 确认对话框与编辑对话框均已关闭。
    expect(find.byType(AlertDialog), findsNothing);
  });
}