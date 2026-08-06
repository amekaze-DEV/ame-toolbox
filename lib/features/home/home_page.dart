import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/layout/responsive_builder.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/models/layout_mode.dart';
import 'package:ametoolbox/core/models/sync_config.dart';
import 'package:ametoolbox/core/modules/module_contract.dart';
import 'package:ametoolbox/core/providers/layout_provider.dart';
import 'package:ametoolbox/core/providers/module_provider.dart';
import 'package:ametoolbox/core/providers/sync_provider.dart';
import 'package:ametoolbox/features/home/module_card_widget.dart';
import 'package:ametoolbox/features/home/nav_item.dart';
import 'package:ametoolbox/features/settings/settings_page.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

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
      appBar: selectedModule == null
          ? AppBar(
              title: const Text('工具台'),
              actions: [
                const _SyncStatusAppBarAction(),
                AdaptiveIconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: '设置',
                  onPressed: () => _openSettings(context),
                ),
              ],
            )
          : null,
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
              appBar: selectedModule == null
                  ? AppBar(
                      title: const Text('工具台'),
                    )
                  : null,
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
      builder: (_) => const SettingsPage(),
    ),
  );
}

/// 主页内容：支持拖拽排序的模块卡片网格。
class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutMode = ref.watch(layoutControllerProvider).layoutMode;
    final moduleController = ref.watch(moduleControllerProvider);
    final enabledModules = moduleController.enabledModules;
    final dashboardWidgets = _collectDashboardWidgets(context, ref, enabledModules);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: layoutMode == LayoutMode.portrait
          ? CustomScrollView(
              slivers: [
                if (dashboardWidgets.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: dashboardWidgets[index],
                      ),
                      childCount: dashboardWidgets.length,
                    ),
                  ),
                SliverReorderableList(
                  itemCount: enabledModules.length,
                  proxyDecorator: _proxyDecorator,
                  itemBuilder: (context, index) {
                    final module = enabledModules[index];
                    return _ModuleCardListItem(
                      key: ValueKey(module.definition.id),
                      module: module,
                      onTap: () => _selectModule(ref, index + 1),
                    );
                  },
                  onReorder: (oldIndex, newIndex) =>
                      moduleController.reorderEnabledModules(oldIndex, newIndex),
                ),
              ],
            )
          : CustomScrollView(
              slivers: [
                if (dashboardWidgets.isNotEmpty)
                  SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.6,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => dashboardWidgets[index],
                      childCount: dashboardWidgets.length,
                    ),
                  ),
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final module = enabledModules[index];
                      return _DraggableModuleCard(
                        key: ValueKey(module.definition.id),
                        module: module,
                        index: index,
                        onTap: () => _selectModule(ref, index + 1),
                      );
                    },
                    childCount: enabledModules.length,
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _collectDashboardWidgets(
    BuildContext context,
    WidgetRef ref,
    List<ModuleContract> enabledModules,
  ) {
    final widgets = <Widget>[];
    for (final module in enabledModules) {
      widgets.addAll(module.buildDashboardWidgets(context, ref));
    }
    return widgets;
  }

  Widget _proxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final elevationValue = Tween<double>(begin: 0, end: 6)
            .animate(animation)
            .value;
        return Material(
          elevation: elevationValue,
          borderRadius: BorderRadius.circular(12),
          child: child,
        );
      },
      child: child,
    );
  }

  void _selectModule(WidgetRef ref, int navIndex) {
    ref.read(_selectedNavIndexProvider.notifier).state = navIndex;
  }
}

/// 竖屏列表中的可拖拽模块卡片项。
class _ModuleCardListItem extends StatelessWidget {
  const _ModuleCardListItem({
    super.key,
    required this.module,
    required this.onTap,
  });

  final ModuleContract module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ModuleCard(
        iconName: module.definition.iconName,
        name: module.definition.name,
        summary: module.summary,
        onTap: onTap,
      ),
    );
  }
}

/// 横屏网格中的可拖拽模块卡片项。
class _DraggableModuleCard extends ConsumerWidget {
  const _DraggableModuleCard({
    super.key,
    required this.module,
    required this.index,
    required this.onTap,
  });

  final ModuleContract module;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moduleController = ref.read(moduleControllerProvider);
    final card = ModuleCard(
      iconName: module.definition.iconName,
      name: module.definition.name,
      summary: module.summary,
      onTap: onTap,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Draggable<int>(
          data: index,
          feedback: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: card,
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: card,
          ),
          child: DragTarget<int>(
            onWillAcceptWithDetails: (details) => details.data != index,
            onAcceptWithDetails: (details) =>
                moduleController.reorderEnabledModules(details.data, index),
            builder: (context, candidateData, rejectedData) => card,
          ),
        );
      },
    );
  }
}

/// 自适应底部导航栏。
///
/// 在窄宽度/竖屏模式下自动均分每个导航项宽度，使所有标签平铺显示；
/// 宽度充足时恢复固定 72 像素的项宽。
class _ScrollableBottomNav extends StatefulWidget {
  const _ScrollableBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onItemSelected,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  static const double maxItemWidth = 72;
  static const double minItemWidth = 56;

  @override
  State<_ScrollableBottomNav> createState() => _ScrollableBottomNavState();
}

class _ScrollableBottomNavState extends State<_ScrollableBottomNav> {
  final ScrollController _controller = ScrollController();
  double _itemWidth = _ScrollableBottomNav.maxItemWidth;

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
      final itemOffset = index * _itemWidth;
      final itemEnd = itemOffset + _itemWidth;
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

  double _computeItemWidth(double availableWidth) {
    return (availableWidth / widget.items.length).clamp(
      _ScrollableBottomNav.minItemWidth,
      _ScrollableBottomNav.maxItemWidth,
    );
  }

  bool _fitsWithoutScroll(double availableWidth) {
    return availableWidth >=
        _ScrollableBottomNav.maxItemWidth * widget.items.length;
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fits = _fitsWithoutScroll(constraints.maxWidth);
            _itemWidth = fits
                ? _ScrollableBottomNav.maxItemWidth
                : _computeItemWidth(constraints.maxWidth);
            final children = List.generate(widget.items.length, (i) {
              return _NavItemButton(
                item: widget.items[i],
                selected: i == widget.currentIndex,
                width: _itemWidth,
                onTap: () => widget.onItemSelected(i),
              );
            });

            if (fits) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: children,
              );
            }

            return SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: inputMode == InputMode.touch
                  ? const BouncingScrollPhysics()
                  : const ClampingScrollPhysics(),
              child: Row(children: children),
            );
          },
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
            Consumer(
              builder: (context, ref, child) {
                final syncService = ref.watch(syncServiceProvider);
                if (!syncService.config.enabled) return const SizedBox.shrink();
                return const _SyncStatusRailItem();
              },
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

  double get _labelFontSize {
    if (width == null) return 10;
    if (width! >= 64) return 10;
    if (width! >= 56) return 9;
    return 8;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: width ?? double.infinity,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                fontSize: _labelFontSize,
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 竖屏标题栏中的同步状态入口。
///
/// WebDAV 关闭时不显示；点击可触发立即同步。
class _SyncStatusAppBarAction extends ConsumerWidget {
  const _SyncStatusAppBarAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);
    if (!syncService.config.enabled) return const SizedBox.shrink();

    final (icon, color, tooltip) = _statusInfo(context, syncService.config, syncService.isSyncing);

    return AdaptiveIconButton(
      icon: Icon(icon, color: color),
      tooltip: tooltip,
      onPressed: syncService.isSyncing ? null : () => syncService.startSync(),
    );
  }
}

/// 横屏导航栏中设置按钮上方的同步状态入口。
///
/// WebDAV 关闭时不显示。
class _SyncStatusRailItem extends ConsumerWidget {
  const _SyncStatusRailItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);
    final (icon, color, label) = _statusInfo(context, syncService.config, syncService.isSyncing);

    return InkWell(
      onTap: syncService.isSyncing ? null : () => syncService.startSync(),
      child: Container(
        width: 80,
        height: 72,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

(IconData, Color, String) _statusInfo(
  BuildContext context,
  SyncConfig config,
  bool isSyncing,
) {
  final colorScheme = Theme.of(context).colorScheme;

  if (isSyncing) {
    return (Icons.sync, colorScheme.primary, '同步中');
  }

  return switch (config.lastSyncStatus) {
    SyncStatus.success => (Icons.check_circle, colorScheme.tertiary, '已同步'),
    SyncStatus.failed => (Icons.error, colorScheme.error, '同步失败'),
    _ => (Icons.cloud_off, colorScheme.outline, '未同步'),
  };
}
