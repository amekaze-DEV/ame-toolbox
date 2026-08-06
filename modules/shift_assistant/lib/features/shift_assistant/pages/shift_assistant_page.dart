import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shift_config_provider.dart';
import 'month_calendar_view.dart';
import 'shift_dashboard_page.dart';

/// 倒班助手主页面。
///
/// 以底部导航在「仪表盘」与「日历」之间切换，页面内嵌工具栏提供设置入口。
class ShiftAssistantPage extends ConsumerStatefulWidget {
  const ShiftAssistantPage({super.key});

  @override
  ConsumerState<ShiftAssistantPage> createState() => _ShiftAssistantPageState();
}

class _ShiftAssistantPageState extends ConsumerState<ShiftAssistantPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(shiftConfigProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        automaticallyImplyLeading: false,
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: const [
                ShiftDashboardPage(),
                MonthCalendarView(),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '仪表盘',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '',
          ),
        ],
      ),
    );
  }
}
