import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/layout/responsive_builder.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/models/layout_mode.dart';
import 'package:ametoolbox/core/providers/layout_provider.dart';
import 'package:ametoolbox/core/providers/module_provider.dart';
import 'package:ametoolbox/features/home/module_card_widget.dart';
import 'package:ametoolbox/features/home/nav_item.dart';
import 'package:ametoolbox/features/home/sync_status_widget.dart';
import 'package:ametoolbox/features/module_management/module_management_page.dart';
import 'package:ametoolbox/features/settings/layout_settings_page.dart';
import 'package:ametoolbox/features/settings/theme_settings_page.dart';

/// 应用主页与自适应导航栏。
///
/// 竖屏时导航栏位于底部，横屏时导航栏位于左侧。
/// 导航项第一项固定为"主页"，后续为已启用模块；空间不足时自动滚动。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveBuilder(
      portraitBuilder: (context) => const _BottomNavScaffold(),
      landscapeBuilder: (context) => const _RailNavScaffold(),
    );
  }
}

/// 导航选中索引：不持久化，每次启动重置为首页。
final _selectedNavIndexProvider = StateProvider<int>((ref) => 0);

/// 竖屏底部导航布局。
class _BottomNavScaffold extends ConsumerWidget {
  const _BottomNavScaffold();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navItems = ref.watch(navItemsProvider);
    final selectedIndex = ref.watch(_selectedNavIndexProvider);
    final moduleController = ref.watch(moduleControllerProvider);
    final selectedModule = selectedIndex > 0 && selectedIndex <= navItems.length
        ? moduleController.enabledModules.elementAtOrNull(selectedIndex - 1)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('工具台'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: selectedModule != null
          ? selectedModule.buildPage(context, ref)
          : const _HomeContent(),
      bottomNavigationBar: _ScrollableBottomNav(
        items: navItems,
        currentIndex: selectedIndex,
        onItemSelected: (index) => ref.read(_selectedNavIndexProvider.notifier).state = index,
      ),
    );
  }
}

/// 横屏左侧导航布局。
class _RailNavScaffold extends ConsumerWidget {
  const _RailNavScaffold();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navItems = ref.watch(navItemsProvider);
    final selectedIndex = ref.watch(_selectedNavIndexProvider);
    final moduleController = ref.watch(moduleControllerProvider);
    final selectedModule = selectedIndex > 0 && selectedIndex <= navItems.length
        ? moduleController.enabledModules.elementAtOrNull(selectedIndex - 1)
        : null;

    return Scaffold(
      body: Row(
        children: [
          _ScrollableRailNav(
            items: navItems,
            currentIndex: selectedIndex,
            onItemSelected: (index) => ref.read(_selectedNavIndexProvider.notifier).state = index,
            onSettingsTap: () => _openSettings(context),
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('工具台'),
              ),
              body: selectedModule != null
                  ? selectedModule.buildPage(context, ref)
                  : const _HomeContent(),
            ),
          ),
        ],
      ),
    );
  }
}

void _openSettings(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const _SettingsPlaceholderPage(),
    ),
  );
}

/// 设置占位页（TASK-06 实现正式设置页后替换）。
class _SettingsPlaceholderPage extends StatelessWidget {
  const _SettingsPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('主题与配色'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ThemeSettingsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.aspect_ratio),
            title: const Text('布局与显示'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LayoutSettingsPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: const Text('模块管理'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ModuleManagementPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 主页内容：模块卡片网格 + 同步状态卡片。
class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutMode = ref.watch(layoutControllerProvider).layoutMode;
    final moduleController = ref.watch(moduleControllerProvider);
    final enabledModules = moduleController.enabledModules;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: CustomScrollView(
        slivers: [
          if (layoutMode == LayoutMode.portrait)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == enabledModules.length) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SyncStatusCard(),
                    );
                  }
                  final module = enabledModules[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ModuleCard(
                      iconName: module.definition.iconName,
                      name: module.definition.name,
                      summary: module.summary,
                      onTap: () => _selectModule(ref, index + 1),
                    ),
                  );
                },
                childCount: enabledModules.length + 1,
              ),
            )
          else
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == enabledModules.length) {
                    return const SyncStatusCard();
                  }
                  final module = enabledModules[index];
                  return ModuleCard(
                    iconName: module.definition.iconName,
                    name: module.definition.name,
                    summary: module.summary,
                    onTap: () => _selectModule(ref, index + 1),
                  );
                },
                childCount: enabledModules.length + 1,
              ),
            ),
        ],
      ),
    );
  }

  void _selectModule(WidgetRef ref, int navIndex) {
    ref.read(_selectedNavIndexProvider.notifier).state = navIndex;
  }
}

/// 可水平滚动的底部导航栏。
class _ScrollableBottomNav extends StatefulWidget {
  const _ScrollableBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onItemSelected,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  static const double itemWidth = 72;

  @override
  State<_ScrollableBottomNav> createState() => _ScrollableBottomNavState();
}

class _ScrollableBottomNavState extends State<_ScrollableBottomNav> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(_ScrollableBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _ensureVisible(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ensureVisible(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      final viewportWidth = _controller.position.viewportDimension;
      final itemOffset = index * _ScrollableBottomNav.itemWidth;
      final itemEnd = itemOffset + _ScrollableBottomNav.itemWidth;
      final currentOffset = _controller.offset;
      final currentEnd = currentOffset + viewportWidth;

      if (itemOffset < currentOffset) {
        _controller.animateTo(
          itemOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (itemEnd > currentEnd) {
        _controller.animateTo(
          itemEnd - viewportWidth,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inputMode = InputModeScope.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      height: 72,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          physics: inputMode == InputMode.touch
              ? const BouncingScrollPhysics()
              : const ClampingScrollPhysics(),
          child: Row(
            children: List.generate(widget.items.length, (i) {
              return _NavItemButton(
                item: widget.items[i],
                selected: i == widget.currentIndex,
                width: _ScrollableBottomNav.itemWidth,
                onTap: () => widget.onItemSelected(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// 可垂直滚动的左侧导航栏，设置入口固定在底部。
class _ScrollableRailNav extends StatefulWidget {
  const _ScrollableRailNav({
    required this.items,
    required this.currentIndex,
    required this.onItemSelected,
    required this.onSettingsTap,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onSettingsTap;

  @override
  State<_ScrollableRailNav> createState() => _ScrollableRailNavState();
}

class _ScrollableRailNavState extends State<_ScrollableRailNav> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(_ScrollableRailNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _ensureVisible(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ensureVisible(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      const itemHeight = 72.0;
      final viewportHeight = _controller.position.viewportDimension;
      final itemOffset = index * itemHeight;
      final itemEnd = itemOffset + itemHeight;
      final currentOffset = _controller.offset;
      final currentEnd = currentOffset + viewportHeight;

      if (itemOffset < currentOffset) {
        _controller.animateTo(
          itemOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (itemEnd > currentEnd) {
        _controller.animateTo(
          itemEnd - viewportHeight,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inputMode = InputModeScope.of(context);

    return Container(
      width: 80,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _controller,
                physics: inputMode == InputMode.touch
                    ? const BouncingScrollPhysics()
                    : const ClampingScrollPhysics(),
                child: Column(
                  children: List.generate(widget.items.length, (i) {
                    return _NavItemButton(
                      item: widget.items[i],
                      selected: i == widget.currentIndex,
                      height: 72,
                      onTap: () => widget.onItemSelected(i),
                    );
                  }),
                ),
              ),
            ),
            const Divider(height: 1),
            _NavItemButton(
              item: const NavItem(
                icon: Icons.settings_outlined,
                label: '设置',
                moduleId: 'settings',
              ),
              selected: false,
              height: 72,
              onTap: widget.onSettingsTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// 单个导航项按钮。
class _NavItemButton extends StatelessWidget {
  const _NavItemButton({
    required this.item,
    required this.selected,
    required this.onTap,
    this.width,
    this.height,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border(
            bottom: width != null && selected
                ? BorderSide(color: colorScheme.primary, width: 3)
                : BorderSide.none,
            left: height != null && selected
                ? BorderSide(color: colorScheme.primary, width: 4)
                : BorderSide.none,
          ),
          color: selected ? colorScheme.primaryContainer : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
