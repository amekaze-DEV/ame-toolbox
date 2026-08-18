import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import '../helpers/fake_storage_service.dart';
import 'package:shift_assistant_module/features/shift_assistant/data/shift_config_repository.dart';
import 'package:shift_assistant_module/features/shift_assistant/models/shift_config.dart';
import 'package:shift_assistant_module/features/shift_assistant/pages/month_calendar_view.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/holiday_data_controller.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/holiday_data_provider.dart';

import 'package:shift_assistant_module/features/shift_assistant/providers/shift_config_controller.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/shift_config_provider.dart';
import 'package:shift_assistant_module/features/shift_assistant/services/holiday_data_service.dart';

void main() {
  group('MonthCalendarView', () {
    testWidgets('renders weekday header and group chips', (tester) async {
      await _pumpCalendarView(tester, _configWithThreeGroups());

      expect(find.text('一'), findsOneWidget);
      expect(find.text('甲班'), findsWidgets);
      expect(find.text('乙班'), findsWidgets);
      expect(find.text('丙班'), findsWidgets);
    });

    testWidgets('adapts toolbar to two rows on narrow widths',
        (tester) async {
      await _pumpCalendarView(
        tester,
        _configWithThreeGroups(),
        // 400px 为应用窗口最小可用宽度（日历完整显示所需宽度）。
        size: const Size(400, 600),
      );

      // 窄宽度下无溢出，工具栏切换为两行：第一行含轮班选择，第二行含今日。
      expect(tester.takeException(), isNull);
      expect(find.text('今日'), findsWidgets);
      expect(find.text('日期转跳'), findsWidgets);
    });

    testWidgets(
        'long rotation name ellipsizes without overflow on narrow widths',
        (tester) async {
      await _pumpCalendarView(
        tester,
        _configWithLongRotationName(),
        // 400px 为应用窗口最小可用宽度；长名称下轮班选择框应收缩省略。
        size: const Size(400, 600),
      );

      // 长轮班名称 + 窄窗口下轮班选择框收缩省略，不报溢出。
      expect(tester.takeException(), isNull);
      expect(find.text('今日'), findsWidgets);
    });

    testWidgets('clicking title in day view shows month picker grid',
        (tester) async {
      await _pumpCalendarView(tester, _configWithThreeGroups());

      // 日视图标题为"2026年8月"（基于配置中的 baseDate: 2026-08-01）。
      expect(find.text('2026年8月'), findsOneWidget);

      // 点击标题，切换到月视图。
      await tester.tap(find.text('2026年8月'));
      await tester.pumpAndSettle();

      // 标题变为"2026年"，显示 12 个月份格。
      expect(find.text('2026年'), findsOneWidget);
      expect(find.text('1月'), findsOneWidget);
      expect(find.text('8月'), findsOneWidget);
      expect(find.text('12月'), findsOneWidget);
    });

    testWidgets('clicking month in month picker returns to day view',
        (tester) async {
      await _pumpCalendarView(tester, _configWithThreeGroups());

      // 点击标题进入月视图。
      await tester.tap(find.text('2026年8月'));
      await tester.pumpAndSettle();

      // 点击 3 月，回到日视图，标题变为"2026年3月"。
      await tester.tap(find.text('3月'));
      await tester.pumpAndSettle();

      expect(find.text('2026年3月'), findsOneWidget);
      // 日视图组件应重新出现。
      expect(find.text('一'), findsOneWidget);
    });

    testWidgets('clicking year in month view opens year picker',
        (tester) async {
      await _pumpCalendarView(tester, _configWithThreeGroups());

      // 日视图 → 月视图（点击标题）。
      await tester.tap(find.text('2026年8月'));
      await tester.pumpAndSettle();

      // 月视图 → 年视图（点击"2026年"标题）。
      await tester.tap(find.text('2026年'));
      await tester.pumpAndSettle();

      // 标题变为"2020-2031年"，显示 12 个年份格（以本十年 2020 为起点）。
      expect(find.text('2020-2031年'), findsOneWidget);
      expect(find.text('2020年'), findsOneWidget);
      expect(find.text('2026年'), findsOneWidget);
      expect(find.text('2031年'), findsOneWidget);
    });

    testWidgets('clicking year in year picker returns to month view',
        (tester) async {
      await _pumpCalendarView(tester, _configWithThreeGroups());

      // 日 → 月 → 年。
      await tester.tap(find.text('2026年8月'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026年'));
      await tester.pumpAndSettle();

      // 点击 2024 年，回到月视图。
      await tester.tap(find.text('2024年'));
      await tester.pumpAndSettle();

      expect(find.text('2024年'), findsOneWidget);
      // 月份网格应重新出现。
      expect(find.text('8月'), findsOneWidget);
    });

    testWidgets('year view allows navigation between year ranges',
        (tester) async {
      await _pumpCalendarView(tester, _configWithThreeGroups());

      // 日 → 月 → 年。
      await tester.tap(find.text('2026年8月'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026年'));
      await tester.pumpAndSettle();

      // 点击左箭头，进入上一个 10 年窗口（2010-2021年）。
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('2010-2021年'), findsOneWidget);
      expect(find.text('2021年'), findsOneWidget);
    });

    testWidgets('month view arrows navigate between years', (tester) async {
      await _pumpCalendarView(tester, _configWithThreeGroups());

      // 日 → 月。
      await tester.tap(find.text('2026年8月'));
      await tester.pumpAndSettle();

      // 点击右箭头，进入下一年（2027年）。
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('2027年'), findsOneWidget);
      expect(find.text('8月'), findsOneWidget);
    });

    testWidgets('today button resets to day view from any level',
        (tester) async {
      await _pumpCalendarView(tester, _configWithThreeGroups());

      // 进入年视图。
      await tester.tap(find.text('2026年8月'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026年'));
      await tester.pumpAndSettle();

      // 点击"今日"按钮。
      await tester.tap(find.text('今日'));
      await tester.pumpAndSettle();

      // 回到日视图，标题为当前年月。
      final now = DateTime.now();
      expect(find.text('${now.year}年${now.month}月'), findsOneWidget);
      // 日视图组件应重新出现。
      expect(find.text('一'), findsOneWidget);
    });

    testWidgets('month picker renders months correctly', (tester) async {
      await _pumpCalendarView(tester, _configWithThreeGroups());

      // 进入月视图。
      await tester.tap(find.text('2026年8月'));
      await tester.pumpAndSettle();

      // 12 个月份格均渲染。
      expect(find.text('1月'), findsOneWidget);
      expect(find.text('8月'), findsOneWidget);
      expect(find.text('12月'), findsOneWidget);
    });

    testWidgets('year picker renders years correctly', (tester) async {
      await _pumpCalendarView(tester, _configWithThreeGroups());

      // 日 → 月 → 年。
      await tester.tap(find.text('2026年8月'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026年'));
      await tester.pumpAndSettle();

      // 12 个年份格均渲染。
      expect(find.text('2020年'), findsOneWidget);
      expect(find.text('2026年'), findsOneWidget);
      expect(find.text('2031年'), findsOneWidget);
    });

    testWidgets('month picker fits within wide window without overflow',
        (tester) async {
      await _pumpCalendarView(
        tester,
        _configWithThreeGroups(),
        // 宽窗口（如最大化后的宽屏）。
        size: const Size(1920, 1080),
      );

      await tester.tap(find.text('2026年8月'));
      await tester.pumpAndSettle();

      // 网格完整显示，无溢出异常，12 个月份格均在可视区域内。
      expect(tester.takeException(), isNull);
      expect(find.text('1月'), findsOneWidget);
      expect(find.text('12月'), findsOneWidget);
    });

    testWidgets('year picker fits within wide window without overflow',
        (tester) async {
      await _pumpCalendarView(
        tester,
        _configWithThreeGroups(),
        size: const Size(1920, 1080),
      );

      await tester.tap(find.text('2026年8月'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026年'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('2020年'), findsOneWidget);
      expect(find.text('2031年'), findsOneWidget);
    });

    testWidgets('month picker fits within short window without overflow',
        (tester) async {
      await _pumpCalendarView(
        tester,
        _configWithThreeGroups(),
        // 矮窗口（横向长条）。
        size: const Size(1200, 280),
      );

      await tester.tap(find.text('2026年8月'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('1月'), findsOneWidget);
      expect(find.text('12月'), findsOneWidget);
    });

    testWidgets('month picker fits within narrow window without overflow',
        (tester) async {
      await _pumpCalendarView(
        tester,
        _configWithThreeGroups(),
        // 窄窗口（竖屏长条）。
        size: const Size(360, 800),
      );

      await tester.tap(find.text('2026年8月'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('1月'), findsOneWidget);
      expect(find.text('12月'), findsOneWidget);
    });

    testWidgets(
        'month picker grid stays fully inside viewport with zero scroll space',
        (tester) async {
      // 覆盖宽高各异的窗口比例，模拟"界面显示加宽"等场景。
      const sizes = [
        Size(1920, 1080),
        Size(2560, 1440),
        Size(1920, 600),
        Size(1600, 400),
        Size(1200, 300),
        Size(800, 1080),
      ];
      for (final size in sizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(Container()); // 重置上一轮 widget 树。
        await _pumpCalendarView(tester, _configWithThreeGroups());

        await tester.tap(find.text('2026年8月'));
        await tester.pumpAndSettle();

        // 无溢出异常。
        expect(tester.takeException(), isNull, reason: 'overflow at $size');

        // 最后一行末尾格"12月"完整位于视口内（不向下超出）。
        final rect = tester.getRect(find.text('12月'));
        expect(rect.top, greaterThanOrEqualTo(0), reason: '12月 top at $size');
        expect(
          rect.bottom,
          lessThanOrEqualTo(size.height),
          reason: '12月 bottom=${rect.bottom} exceeds ${size.height} at $size',
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));

        // 垂直方向无滚动空间。
        for (final scrollable
            in tester.widgetList<Scrollable>(find.byType(Scrollable))) {
          if (scrollable.axisDirection == AxisDirection.down) {
            final state = tester.state<ScrollableState>(
              find.byWidget(scrollable),
            );
            expect(
              state.position.maxScrollExtent,
              0,
              reason: 'scroll extent ${state.position.maxScrollExtent} at $size',
            );
          }
        }
        await tester.binding.setSurfaceSize(null);
      }
    });
  });
}

Future<void> _pumpCalendarView(
  WidgetTester tester,
  ShiftConfig config, {
  InputMode inputMode = InputMode.mouse,
  Size? size,
}) async {
  if (size != null) {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  final storage = FakeStorageService();
  await storage.initialize();

  final repository = ShiftConfigRepository(storage: storage);
  await repository.save(config);

  final configController = ShiftConfigController(repository: repository);
  await configController.load();

  final holidayController = HolidayDataController(
    service: _NoOpHolidayDataService(),
    configController: configController,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shiftConfigRepositoryProvider.overrideWithValue(repository),
        shiftConfigProvider.overrideWith((ref) => configController),
        holidayDataProvider.overrideWith((ref) => holidayController),
      ],
      child: InputModeScope(
        mode: inputMode,
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
          ),
          home: const Scaffold(body: MonthCalendarView()),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

/// 三班组配置（短轮班名称）。
ShiftConfig _configWithThreeGroups() => ShiftConfig(
      rotations: [
        ShiftRotation(
          id: 'rotation_1',
          name: '测试轮班',
          baseDate: DateTime(2026, 8, 1),
          cycleDays: 3,
          groups: _groups,
          slots: _slots,
          assignments: _assignments,
        ),
      ],
      lastViewedRotationId: 'rotation_1',
    );

/// 长轮班名称配置，用于验证窄宽度下省略显示。
ShiftConfig _configWithLongRotationName() => ShiftConfig(
      rotations: [
        ShiftRotation(
          id: 'rotation_1',
          name: '这是一个非常非常长的轮班名称用于测试省略显示效果',
          baseDate: DateTime(2026, 8, 1),
          cycleDays: 3,
          groups: _groups,
          slots: _slots,
          assignments: _assignments,
        ),
      ],
      lastViewedRotationId: 'rotation_1',
    );

const _groups = [
  ShiftGroup(id: 'group_a', name: '甲班'),
  ShiftGroup(id: 'group_b', name: '乙班'),
  ShiftGroup(id: 'group_c', name: '丙班'),
];

const _slots = [
  ShiftSlot(name: '白班'),
  ShiftSlot(name: '夜班'),
  ShiftSlot(name: '休息'),
];

const _assignments = [
  [0, 1, 2],
  [1, 2, 0],
  [2, 0, 1],
];

/// 不发起网络请求的节假日数据服务占位实现。
class _NoOpHolidayDataService extends HolidayDataService {
  _NoOpHolidayDataService() : super(httpClient: null);

  @override
  Future<Map<String, HolidayInfo>> fetchYear(int year) async => {};
}