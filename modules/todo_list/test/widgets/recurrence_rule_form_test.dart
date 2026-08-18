import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_pattern.dart';
import 'package:todo_list_module/features/todo_list/models/recurrence_rule.dart';
import 'package:todo_list_module/features/todo_list/widgets/recurrence_rule_form.dart';

void main() {
  final start = DateTime(2026, 8, 1);

  Widget wrap(Widget form) => InputModeScope(
        mode: InputMode.touch,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      content: SizedBox(
                        width: 460,
                        child: form,
                      ),
                    ),
                  ),
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> openForm(WidgetTester tester, Widget form) async {
    await tester.pumpWidget(wrap(form));
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
  }

  testWidgets('新增规则：循环周期未设定时禁止保存并显示提示', (tester) async {
    RecurrenceRule? result;
    await openForm(tester, RecurrenceRuleForm(onSubmitted: (r) => result = r));

    // 单个按钮显示「未设定」，无常驻滚轮
    expect(find.byType(CupertinoPicker), findsNothing);
    expect(find.text('未设定'), findsOneWidget);
    expect(find.text('请设置循环周期（间隔数量与周期单位）'), findsOneWidget);
    // 定位方式/参数在未设定时不可用
    expect(find.text('定位方式'), findsNothing);

    // 点击确定被禁止：对话框仍打开、不产生规则
    await tester.ensureVisible(find.text('确定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.text('确定'), findsOneWidget);
  });

  testWidgets('点击按钮展开居中滚轮子面板，确认后回填并允许保存', (tester) async {
    RecurrenceRule? result;
    await openForm(tester, RecurrenceRuleForm(onSubmitted: (r) => result = r));

    // 点击按钮 → 弹出居中对话框内嵌两个滚轮
    await tester.tap(find.text('未设定'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPicker), findsNWidgets(2)); // 间隔 + 单位滚轮

    // 子面板内确认默认值（天 + 1）
    await tester.tap(find.text('确定').last);
    await tester.pumpAndSettle();

    // 回填后显示预览、隐藏提示
    expect(find.text('每 1 天'), findsOneWidget);
    expect(find.text('请设置循环周期（间隔数量与周期单位）'), findsNothing);

    // 可正常保存
    await tester.ensureVisible(find.text('确定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    final p = result!.pattern as EveryXDaysPattern;
    expect(p.interval, 1);
  });

  testWidgets('编辑已有规则：预填循环周期并可保存', (tester) async {
    RecurrenceRule? result;
    await openForm(tester, RecurrenceRuleForm(
      initial: RecurrenceRule(
        pattern: const WeeklyPattern(interval: 6, weekdays: {1}),
        startDate: start,
      ),
      onSubmitted: (r) => result = r,
    ));

    // 预填值 + 自定义标注
    expect(find.text('每 6 周（自定义）'), findsOneWidget);
    expect(find.text('请设置循环周期（间隔数量与周期单位）'), findsNothing);
    // 定位方式可用
    expect(find.text('定位方式'), findsOneWidget);

    // 可保存
    await tester.ensureVisible(find.text('确定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect((result!.pattern as WeeklyPattern).interval, 6);
  });

  testWidgets('子面板切换单位滚轮后周期预览随之变化', (tester) async {
    await openForm(tester, RecurrenceRuleForm(onSubmitted: (_) {}));
    await tester.tap(find.text('未设定'));
    await tester.pumpAndSettle();

    // 拖动右侧单位滚轮向上选“周”
    final unitWheel = find.byType(CupertinoPicker).at(1);
    await tester.drag(unitWheel, const Offset(0, -40));
    await tester.pumpAndSettle();
    expect(find.text('每 1 周'), findsOneWidget);
  });

  testWidgets('「第B天」使用行式编辑器：多天按行预填并可保存', (tester) async {
    RecurrenceRule? result;
    await openForm(tester, RecurrenceRuleForm(
      initial: RecurrenceRule(
        pattern: const EveryXDaysPattern(interval: 4, days: {1, 4}),
        startDate: start,
      ),
      onSubmitted: (r) => result = r,
    ));

    // 行式编辑器（参照「第B月·第C天」）：两行「第几天」下拉 + 添加一组
    expect(find.text('每 4 天'), findsOneWidget);
    expect(find.byType(DropdownMenu<int>), findsNWidgets(2));
    expect(find.text('添加一组'), findsOneWidget);

    // 保存后 days 集合保持一致
    await tester.ensureVisible(find.text('确定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    final p = result!.pattern as EveryXDaysPattern;
    expect(p.interval, 4);
    expect(p.days, {1, 4});
  });
}