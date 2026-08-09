import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shift_config_provider.dart';
import 'month_calendar_view.dart';

/// 倒班助手主页面。
///
/// 默认展示月历视图，工具栏集成年月导航、轮班切换、日期转跳与设置入口。
class ShiftAssistantPage extends ConsumerWidget {
  const ShiftAssistantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(shiftConfigProvider);

    return Scaffold(
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : const MonthCalendarView(),
    );
  }
}
