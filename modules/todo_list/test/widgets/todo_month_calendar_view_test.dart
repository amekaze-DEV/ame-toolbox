import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/holiday_info.dart';
import 'package:todo_list_module/features/todo_list/models/todo_priority.dart';
import 'package:todo_list_module/features/todo_list/widgets/todo_month_calendar_view.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';

/// 构造 [TodoMonthCalendarView] 无状态测试宿主（用于纯渲染断言）。
Widget _host({
  required DateTime displayMonth,
  required DateTime selectedDate,
  required DateTime today,
  Map<DateTime, TodoPriority> markedDates = const {},
  Map<DateTime, TodoDayExtra> dayExtras = const {},
  ValueChanged<DateTime>? onSelectDate,
  ValueChanged<DateTime>? onDateJump,
  CalendarViewLevel viewLevel = CalendarViewLevel.day,
}) {
  return ProviderScope(
    child: InputModeScope(
      mode: InputMode.touch,
      child: MaterialApp(
        home: Scaffold(
          body: TodoMonthCalendarView(
            displayMonth: displayMonth,
            selectedDate: selectedDate,
            today: today,
            markedDates: markedDates,
            dayExtras: dayExtras,
            onSelectDate: onSelectDate ?? (_) {},
            viewLevel: viewLevel,
            onTitleTap: () {},
            onMonthSelected: (_) {},
            onYearSelected: (_) {},
            onPreviousUnit: () {},
            onNextUnit: () {},
            onToday: () {},
            onDateJump: onDateJump,
          ),
        ),
      ),
    ),
  );
}

/// 当月每日附加信息（含节假日、农历、节气、公历节日）。
Map<DateTime, TodoDayExtra> _extrasFor(DateTime month) {
  final extras = <DateTime, TodoDayExtra>{};
  for (var day = 1; day <= DateTime(month.year, month.month + 1, 0).day; day++) {
    extras[DateTime(month.year, month.month, day)] = const TodoDayExtra(
      lunarDate: '初一',
    );
  }
  return extras;
}

/// 有状态测试宿主：模拟页面持有的层级与聚焦状态逻辑（与 [TodoListPage] 一致）。
///
/// 支持模拟页面竖屏（Column + 列表占位）与横屏（Row + 列表占位）两种布局约束，
/// 用于验证三级导航流程及极端窗口尺寸下的网格显示。
class _StatefulCalendarHost extends StatefulWidget {
  const _StatefulCalendarHost({
    super.key,
    required this.initialMonth,
    this.horizontal = false,
    this.onDateJump,
  });

  final DateTime initialMonth;

  /// true 时模拟横屏两列布局（日历位于有界列内，非滚动容器）。
  final bool horizontal;

  /// 日期转跳回调：为 null 时不显示「日期转跳」按钮。
  final ValueChanged<DateTime>? onDateJump;

  @override
  State<_StatefulCalendarHost> createState() => _StatefulCalendarHostState();
}

class _StatefulCalendarHostState extends State<_StatefulCalendarHost> {
  late DateTime _displayMonth;
  late DateTime _selectedDate;
  late CalendarViewLevel _viewLevel;

  @override
  void initState() {
    super.initState();
    _displayMonth = widget.initialMonth;
    _selectedDate = widget.initialMonth;
    _viewLevel = CalendarViewLevel.day;
  }

  /// 标题点击：日→月、月→年、年无操作。
  void _onTitleTap() {
    setState(() {
      _viewLevel = switch (_viewLevel) {
        CalendarViewLevel.day => CalendarViewLevel.month,
        CalendarViewLevel.month => CalendarViewLevel.year,
        CalendarViewLevel.year => CalendarViewLevel.year,
      };
    });
  }

  /// 月份格选中：聚焦该月并返回日视图。
  void _onMonthSelected(int month) {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, month, 1);
      _viewLevel = CalendarViewLevel.day;
    });
  }

  /// 年份格选中：聚焦该年并返回月视图。
  void _onYearSelected(int year) {
    setState(() {
      _displayMonth = DateTime(year, _displayMonth.month, 1);
      _viewLevel = CalendarViewLevel.month;
    });
  }

  /// 层级感知的向前导航：day ±1 月、month ±1 年、year ±10 年。
  void _onPreviousUnit() {
    setState(() {
      final delta = switch (_viewLevel) {
        CalendarViewLevel.day => -1,
        CalendarViewLevel.month => -12,
        CalendarViewLevel.year => -120,
      };
      _displayMonth = DateTime(
        _displayMonth.year,
        _displayMonth.month + delta,
        1,
      );
    });
  }

  /// 层级感知的向后导航：day ±1 月、month ±1 年、year ±10 年。
  void _onNextUnit() {
    setState(() {
      final delta = switch (_viewLevel) {
        CalendarViewLevel.day => 1,
        CalendarViewLevel.month => 12,
        CalendarViewLevel.year => 120,
      };
      _displayMonth = DateTime(
        _displayMonth.year,
        _displayMonth.month + delta,
        1,
      );
    });
  }

  /// 「今天」：任意层级回日视图并聚焦今天。
  void _onToday() {
    setState(() {
      final now = DateTime.now();
      _displayMonth = DateTime(now.year, now.month, 1);
      _viewLevel = CalendarViewLevel.day;
    });
  }

  /// 日期转跳：选中目标日期、翻月并回到日视图。
  void _onDateJump(DateTime date) {
    setState(() {
      _selectedDate = date;
      _displayMonth = DateTime(date.year, date.month, 1);
      _viewLevel = CalendarViewLevel.day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final calendar = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TodoMonthCalendarView(
        displayMonth: _displayMonth,
        selectedDate: _selectedDate,
        today: DateTime.now(),
        markedDates: const {},
        dayExtras: const {},
        viewLevel: _viewLevel,
        onSelectDate: (date) => setState(() => _selectedDate = date),
        onTitleTap: _onTitleTap,
        onMonthSelected: _onMonthSelected,
        onYearSelected: _onYearSelected,
        onPreviousUnit: _onPreviousUnit,
        onNextUnit: _onNextUnit,
        onToday: _onToday,
        onDateJump: widget.onDateJump == null ? null : _onDateJump,
      ),
    );
    final body = widget.horizontal
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // 与真实页面一致：横屏时日视图置于可滚动容器；
                // 月/年视图为自适应缩放网格，无需滚动。
                child: _viewLevel == CalendarViewLevel.day
                    ? SingleChildScrollView(child: calendar)
                    : calendar,
              ),
              const VerticalDivider(width: 1),
              const Expanded(child: SizedBox()),
            ],
          )
        : Column(
            children: [
              calendar,
              const Divider(height: 1),
              const Expanded(child: SizedBox()),
            ],
          );
    return ProviderScope(
      child: InputModeScope(
        mode: InputMode.touch,
        child: MaterialApp(
          home: Scaffold(body: body),
        ),
      ),
    );
  }
}

/// 网格内某文本对应的屏幕矩形。
Rect _rectOf(WidgetTester tester, Finder finder) {
  final box = tester.renderObject(finder) as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

void main() {
  final displayMonth = DateTime(2026, 8, 1);

  testWidgets('节假日显示休标记，调休显示班标记', (tester) async {
    final extras = _extrasFor(displayMonth);
    extras[DateTime(2026, 8, 1)] = const TodoDayExtra(
      lunarDate: '十九',
      holiday: HolidayInfo(name: '建军节', isHoliday: true),
    );
    extras[DateTime(2026, 8, 15)] = const TodoDayExtra(
      lunarDate: '初三',
      holiday: HolidayInfo(name: '调休补班', isWorkday: true),
    );

    await tester.pumpWidget(_host(
      displayMonth: displayMonth,
      selectedDate: DateTime(2026, 8, 1),
      today: DateTime(2026, 8, 1),
      dayExtras: extras,
    ));
    await tester.pumpAndSettle();

    // 休/班尾缀显示
    expect(find.text('1休'), findsOneWidget);
    expect(find.text('15班'), findsOneWidget);
    // 普通日期不显示尾缀
    expect(find.text('16'), findsOneWidget);
  });

  testWidgets('调休上班显示红色，休息/法定节假日显示绿色', (tester) async {
    final extras = _extrasFor(displayMonth);
    extras[DateTime(2026, 8, 1)] = const TodoDayExtra(
      lunarDate: '十九',
      holiday: HolidayInfo(name: '建军节', isHoliday: true),
    );
    extras[DateTime(2026, 8, 15)] = const TodoDayExtra(
      lunarDate: '初三',
      holiday: HolidayInfo(name: '调休补班', isWorkday: true),
    );

    await tester.pumpWidget(_host(
      displayMonth: displayMonth,
      selectedDate: DateTime(2026, 8, 1),
      today: DateTime(2026, 8, 1),
      dayExtras: extras,
    ));
    await tester.pumpAndSettle();

    final colorScheme =
        Theme.of(tester.element(find.byType(TodoMonthCalendarView)))
            .colorScheme;

    // 休息 / 法定节假日（休）：绿色（浅色主题为 Green 800）。
    final holiday = tester.widget<Text>(find.text('1休'));
    expect(holiday.style?.color, const Color(0xFF2E7D32));

    // 调休上班（班）：红色（error），与休区分。
    final workday = tester.widget<Text>(find.text('15班'));
    expect(workday.style?.color, colorScheme.error);
    expect(workday.style?.color, isNot(const Color(0xFF2E7D32)));
  });

  testWidgets('农历、节气、公历节日按优先级显示', (tester) async {
    final extras = _extrasFor(displayMonth);
    // 节气优先于农历
    extras[DateTime(2026, 8, 7)] = const TodoDayExtra(
      lunarDate: '廿五',
      solarTerm: '立秋',
    );
    // 公历节日优先于节气
    extras[DateTime(2026, 8, 3)] = const TodoDayExtra(
      lunarDate: '廿一',
      solarTerm: '某某',
      solarFestivals: ['建军节'],
    );
    // 仅农历
    extras[DateTime(2026, 8, 8)] = const TodoDayExtra(lunarDate: '廿六');

    await tester.pumpWidget(_host(
      displayMonth: displayMonth,
      selectedDate: DateTime(2026, 8, 1),
      today: DateTime(2026, 8, 1),
      dayExtras: extras,
    ));
    await tester.pumpAndSettle();

    expect(find.text('立秋'), findsOneWidget);
    expect(find.text('建军节'), findsOneWidget);
    expect(find.text('廿六'), findsOneWidget);
    // 廿一被建军节覆盖，廿五被立秋覆盖，不显示
    expect(find.text('廿一'), findsNothing);
    expect(find.text('廿五'), findsNothing);
  });

  testWidgets('有待办的日期显示标记圆点', (tester) async {
    await tester.pumpWidget(_host(
      displayMonth: displayMonth,
      selectedDate: DateTime(2026, 8, 1),
      today: DateTime(2026, 8, 1),
      markedDates: {DateTime(2026, 8, 5): TodoPriority.medium},
      dayExtras: _extrasFor(displayMonth),
    ));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('todo_mark_2026_8_5')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('todo_mark_2026_8_6')),
      findsNothing,
    );
  });

  testWidgets('色点颜色按当日最高优先级显示', (tester) async {
    await tester.pumpWidget(_host(
      displayMonth: displayMonth,
      selectedDate: DateTime(2026, 8, 1),
      today: DateTime(2026, 8, 1),
      markedDates: {
        DateTime(2026, 8, 1): TodoPriority.highest,
        DateTime(2026, 8, 2): TodoPriority.daily,
      },
      dayExtras: _extrasFor(displayMonth),
    ));
    await tester.pumpAndSettle();

    final colorScheme = Theme.of(tester.element(find.byType(TodoMonthCalendarView))).colorScheme;
    final highestDot = tester.widget<Container>(
      find.byKey(const ValueKey('todo_mark_2026_8_1')),
    );
    final dailyDot = tester.widget<Container>(
      find.byKey(const ValueKey('todo_mark_2026_8_2')),
    );

    final highestColor =
        (highestDot.decoration! as BoxDecoration).color;
    final dailyColor = (dailyDot.decoration! as BoxDecoration).color;

    expect(highestColor, colorScheme.error);
    expect(dailyColor, colorScheme.secondary);
    // 最高与日常颜色不同
    expect(highestColor, isNot(dailyColor));
  });

  testWidgets('月初补位显示上月日期，且显示农历与待办标记', (tester) async {
    // 2026-08-01 为周六，周一开头的网格会补入 7/27~7/31 上月日期。
    final extras = _extrasFor(displayMonth);
    // 上月补位日期（7/27）提供农历。
    extras[DateTime(2026, 7, 27)] = const TodoDayExtra(lunarDate: '十四');
    await tester.pumpWidget(_host(
      displayMonth: displayMonth,
      selectedDate: DateTime(2026, 8, 1),
      today: DateTime(2026, 8, 1),
      markedDates: {DateTime(2026, 7, 27): TodoPriority.high},
      dayExtras: extras,
    ));
    await tester.pumpAndSettle();

    // 上月补位日期显示（本月 27 号也存在，故 findsWidgets）
    expect(find.text('27'), findsWidgets);
    // 非本月日期同样显示农历
    expect(find.text('十四'), findsOneWidget);
    // 非本月日期同样显示待办标记
    expect(
      find.byKey(const ValueKey('todo_mark_2026_7_27')),
      findsOneWidget,
    );
  });

  testWidgets('日期强调层级：非当月浅灰加粗、当月常规加粗、当日常规加粗并描边', (tester) async {
    await tester.pumpWidget(_host(
      displayMonth: displayMonth,
      selectedDate: DateTime(2026, 8, 1),
      today: DateTime(2026, 8, 15),
      dayExtras: const {},
    ));
    await tester.pumpAndSettle();

    final colorScheme =
        Theme.of(tester.element(find.byType(TodoMonthCalendarView)))
            .colorScheme;
    final gray = colorScheme.onSurface.withValues(alpha: 0.38);

    // 当日（8/15）：常规加粗 + 单元格描边。
    final today = tester.widget<Text>(find.text('15'));
    expect(today.style?.fontWeight, FontWeight.bold);
    expect(today.style?.color, colorScheme.onSurface);
    final outlined = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('15'),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Container &&
                  (w.decoration as BoxDecoration?)?.border != null,
            ),
          )
          .first,
    );
    final todayBorder = (outlined.decoration! as BoxDecoration).border as Border;
    expect(todayBorder.top.color, colorScheme.primary);

    // 当月普通日期（8/10）：常规加粗、无描边。
    final normal = tester.widget<Text>(find.text('10'));
    expect(normal.style?.fontWeight, FontWeight.bold);
    expect(normal.style?.color, colorScheme.onSurface);
    expect(
      find.ancestor(
        of: find.text('10'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              (w.decoration as BoxDecoration?)?.border != null,
        ),
      ),
      findsNothing,
    );

    // 非当月补位日期：浅灰加粗（数量 = 网格总格数 - 当月天数）。
    final firstDay = DateTime(2026, 8, 1);
    final leadingBlanks = firstDay.weekday - 1;
    final daysInMonth = DateTime(2026, 9, 0).day; // 8 月有 31 天
    final totalCells = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;
    final fillCount = totalCells - daysInMonth;
    final grayTexts = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.style?.color == gray)
        .toList();
    expect(grayTexts, hasLength(fillCount));
    for (final t in grayTexts) {
      expect(t.style?.fontWeight, FontWeight.bold);
    }
  });

  testWidgets('宽屏显示日期转跳按钮，点击弹出日期选择器', (tester) async {
    await tester.pumpWidget(_host(
      displayMonth: displayMonth,
      selectedDate: DateTime(2026, 8, 1),
      today: DateTime(2026, 8, 1),
      dayExtras: _extrasFor(displayMonth),
      onDateJump: (_) {},
    ));
    await tester.pumpAndSettle();

    // 按钮存在。
    expect(find.text('日期转跳'), findsOneWidget);

    // 点击后弹出日期选择器。
    await tester.tap(find.text('日期转跳'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);

    // 关闭弹窗。
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
  });

  testWidgets('未提供 onDateJump 时不显示日期转跳按钮', (tester) async {
    await tester.pumpWidget(_host(
      displayMonth: displayMonth,
      selectedDate: DateTime(2026, 8, 1),
      today: DateTime(2026, 8, 1),
      dayExtras: _extrasFor(displayMonth),
    ));
    await tester.pumpAndSettle();

    expect(find.text('日期转跳'), findsNothing);
  });

  // ---------- 三级导航流程 ----------

  testWidgets('初始层级为日视图，标题为 yyyy年M月', (tester) async {
    await tester.pumpWidget(_StatefulCalendarHost(
      initialMonth: DateTime(2026, 8, 1),
    ));
    await tester.pumpAndSettle();

    expect(find.text('2026年8月'), findsOneWidget);
    // 日视图不显示月份选择格
    expect(find.text('1月'), findsNothing);
  });

  testWidgets('点击标题进入月视图：标题变 yyyy年，出现 1月/8月/12月', (tester) async {
    await tester.pumpWidget(_StatefulCalendarHost(
      initialMonth: DateTime(2026, 8, 1),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2026年8月'));
    await tester.pumpAndSettle();

    expect(find.text('2026年'), findsOneWidget);
    expect(find.text('1月'), findsOneWidget);
    expect(find.text('8月'), findsOneWidget);
    expect(find.text('12月'), findsOneWidget);
  });

  testWidgets('月视图点击 3月 返回日视图并聚焦该月', (tester) async {
    await tester.pumpWidget(_StatefulCalendarHost(
      initialMonth: DateTime(2026, 8, 1),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2026年8月'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3月'));
    await tester.pumpAndSettle();

    expect(find.text('2026年3月'), findsOneWidget);
    expect(find.text('1月'), findsNothing);
  });

  testWidgets('月视图点击标题进入年视图：标题变 2020-2031年', (tester) async {
    await tester.pumpWidget(_StatefulCalendarHost(
      initialMonth: DateTime(2026, 8, 1),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2026年8月'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026年'));
    await tester.pumpAndSettle();

    expect(find.text('2020-2031年'), findsOneWidget);
    expect(find.text('2020年'), findsOneWidget);
    expect(find.text('2026年'), findsOneWidget);
    expect(find.text('2031年'), findsOneWidget);
  });

  testWidgets('年视图点击某年份返回月视图并聚焦该年', (tester) async {
    await tester.pumpWidget(_StatefulCalendarHost(
      initialMonth: DateTime(2026, 8, 1),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2026年8月'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026年'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2024年'));
    await tester.pumpAndSettle();

    // 回月视图并聚焦 2024 年
    expect(find.text('2024年'), findsOneWidget);
    expect(find.text('1月'), findsOneWidget);
  });

  testWidgets('年视图点击标题无操作（层级守卫）', (tester) async {
    await tester.pumpWidget(_StatefulCalendarHost(
      initialMonth: DateTime(2026, 8, 1),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2026年8月'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026年'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2020-2031年'));
    await tester.pumpAndSettle();

    // 仍在年视图
    expect(find.text('2020-2031年'), findsOneWidget);
    expect(find.text('2031年'), findsOneWidget);
  });

  testWidgets('日视图箭头按 ±1 月切换', (tester) async {
    await tester.pumpWidget(_StatefulCalendarHost(
      initialMonth: DateTime(2026, 8, 1),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('下一月'));
    await tester.pumpAndSettle();
    expect(find.text('2026年9月'), findsOneWidget);

    await tester.tap(find.byTooltip('上一月'));
    await tester.pumpAndSettle();
    expect(find.text('2026年8月'), findsOneWidget);
  });

  testWidgets('月视图箭头按 ±1 年切换', (tester) async {
    await tester.pumpWidget(_StatefulCalendarHost(
      initialMonth: DateTime(2026, 8, 1),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2026年8月'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('下一年'));
    await tester.pumpAndSettle();
    expect(find.text('2027年'), findsOneWidget);

    await tester.tap(find.byTooltip('上一年'));
    await tester.pumpAndSettle();
    expect(find.text('2026年'), findsOneWidget);
  });

  testWidgets('年视图箭头按 ±10 年窗口切换', (tester) async {
    await tester.pumpWidget(_StatefulCalendarHost(
      initialMonth: DateTime(2026, 8, 1),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2026年8月'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026年'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('下一个十年窗口'));
    await tester.pumpAndSettle();
    expect(find.text('2030-2041年'), findsOneWidget);

    await tester.tap(find.byTooltip('上一个十年窗口'));
    await tester.pumpAndSettle();
    expect(find.text('2020-2031年'), findsOneWidget);

    await tester.tap(find.byTooltip('上一个十年窗口'));
    await tester.pumpAndSettle();
    expect(find.text('2010-2021年'), findsOneWidget);
  });

  testWidgets('年份窗口按 10 整除对齐', (tester) async {
    // 2019 → 2010-2021
    await tester.pumpWidget(_StatefulCalendarHost(
      initialMonth: DateTime(2019, 6, 1),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2019年6月'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2019年'));
    await tester.pumpAndSettle();
    expect(find.text('2010-2021年'), findsOneWidget);

    // 2030 → 2030-2041（10 整除对齐）
    // 使用独立 key 强制重建宿主 State，避免复用上一个 initState 的聚焦状态。
    await tester.pumpWidget(_StatefulCalendarHost(
      key: const ValueKey('host-2030'),
      initialMonth: DateTime(2030, 6, 1),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2030年6月'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2030年'));
    await tester.pumpAndSettle();
    expect(find.text('2030-2041年'), findsOneWidget);
  });

  testWidgets('今天按钮在月视图点击返回日视图并聚焦今天', (tester) async {
    await tester.pumpWidget(_StatefulCalendarHost(
      initialMonth: DateTime(2025, 3, 1),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2025年3月'));
    await tester.pumpAndSettle();
    expect(find.text('2025年'), findsOneWidget);

    await tester.tap(find.text('今天'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    expect(find.text('${now.year}年${now.month}月'), findsOneWidget);
    expect(find.text('1月'), findsNothing);
  });

  testWidgets('日期转跳按钮在月视图保持可见', (tester) async {
    await tester.pumpWidget(_StatefulCalendarHost(
      initialMonth: DateTime(2026, 8, 1),
      onDateJump: (_) {},
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2026年8月'));
    await tester.pumpAndSettle();

    expect(find.text('日期转跳'), findsOneWidget);
    expect(find.text('今天'), findsOneWidget);
  });

  testWidgets('年视图日期转跳后回到日视图并聚焦所选日期', (tester) async {
    await tester.pumpWidget(_StatefulCalendarHost(
      initialMonth: DateTime(2026, 8, 1),
      onDateJump: (_) {},
    ));
    await tester.pumpAndSettle();

    // 进入年视图
    await tester.tap(find.text('2026年8月'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026年'));
    await tester.pumpAndSettle();
    expect(find.text('2020-2031年'), findsOneWidget);

    // 日期转跳仍在
    expect(find.text('日期转跳'), findsOneWidget);
  });

  // ---------- 极端窗口尺寸（月/年视图不溢出、无滚动） ----------

  const extremeSizes = [
    Size(1920, 1080),
    Size(2560, 1440),
    Size(1920, 600),
    Size(1600, 400),
    Size(1200, 300),
    Size(800, 1080),
  ];

  for (final size in extremeSizes) {
    testWidgets('月视图在 ${size.width.toInt()}x${size.height.toInt()} 下完整显示、无溢出无滚动',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_StatefulCalendarHost(
        initialMonth: DateTime(2026, 8, 1),
        horizontal: size.width > size.height,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026年8月'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // 首末格完整在视口内
      final viewport = tester.getRect(find.byType(Scaffold));
      final first = _rectOf(tester, find.text('1月'));
      final last = _rectOf(tester, find.text('12月'));
      expect(viewport.contains(first.topLeft), isTrue);
      expect(viewport.contains(first.bottomRight), isTrue);
      expect(viewport.contains(last.topLeft), isTrue);
      expect(viewport.contains(last.bottomRight), isTrue);
      // 垂直方向无滚动
      for (final scrollable in tester
          .widgetList<Scrollable>(find.byType(Scrollable))) {
        expect(scrollable.controller?.position.maxScrollExtent ?? 0, 0);
      }
    });

    testWidgets('年视图在 ${size.width.toInt()}x${size.height.toInt()} 下完整显示、无溢出无滚动',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_StatefulCalendarHost(
        initialMonth: DateTime(2026, 8, 1),
        horizontal: size.width > size.height,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026年8月'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026年'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final viewport = tester.getRect(find.byType(Scaffold));
      final first = _rectOf(tester, find.text('2020年'));
      final last = _rectOf(tester, find.text('2031年'));
      expect(viewport.contains(first.topLeft), isTrue);
      expect(viewport.contains(first.bottomRight), isTrue);
      expect(viewport.contains(last.topLeft), isTrue);
      expect(viewport.contains(last.bottomRight), isTrue);
      for (final scrollable in tester
          .widgetList<Scrollable>(find.byType(Scrollable))) {
        expect(scrollable.controller?.position.maxScrollExtent ?? 0, 0);
      }
    });
  }
}
