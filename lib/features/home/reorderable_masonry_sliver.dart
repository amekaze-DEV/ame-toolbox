import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// 可拖拽排序的瀑布流 sliver。
///
/// 基于 [SliverMasonryGrid]（瀑布流布局，自动填充最短列，实现"宽度固定、
/// 高度自由"的双列网格），叠加自研的拖拽排序机制：
/// 每个子项长按后拖动（与竖屏拖动方式一致），松手后回调 [onReorder]
/// 报告新的线性顺序。底层顺序变化后，瀑布流会自动按新顺序重新摆放。
///
/// 注意：`flutter_staggered_grid_view` 0.7.0 不提供可拖拽的瀑布流组件，
/// 因此这里在标准瀑布流之上自行实现拖拽，以满足"双列＋高度自由＋可拖动"。
///
/// 卡死规避：子项里可能包含真实的 `TextField` / Riverpod 等复杂组件。
/// 拖拽反馈（[LongPressDraggable.feedback]）与拖拽占位
/// （[LongPressDraggable.childWhenDragging]）都渲染在 Overlay / 替换树中，
/// 若在那里重建完整子项，会在每次拖拽移动时反复新建控件，导致手势竞争与卡死。
/// 因此本组件只构建一次真实子项，反馈与占位均使用轻量占位，绝不重复调用
/// [ReorderableMasonrySliver.itemBuilder]。
class ReorderableMasonrySliver extends StatefulWidget {
  const ReorderableMasonrySliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
    this.feedbackBuilder,
    this.placeholderBuilder,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
  });

  /// 子项数量。
  final int itemCount;

  /// 用于构建每个子项。
  final IndexedWidgetBuilder itemBuilder;

  /// 拖拽时跟随指针的反馈组件构建器。
  ///
  /// 若未提供，则使用默认的轻量占位卡。复杂子项（含 TextField/Provider 等）
  /// 应提供此构建器返回一个**静态、无状态、无交互**的视觉占位，避免在 Overlay
  /// 中重建完整子项导致卡死。
  final IndexedWidgetBuilder? feedbackBuilder;

  /// 拖拽期间原位置显示的占位组件构建器。
  ///
  /// 若未提供，则使用固定高度的半透明灰色块。建议复杂子项提供与真实卡片高度
  /// 接近的静态占位，以保持瀑布流布局稳定。
  final IndexedWidgetBuilder? placeholderBuilder;

  /// 拖拽排序完成时的回调，参数为"原位置索引、目标位置索引"。
  ///
  /// 目标位置索引含义与 [ReorderableMasonrySliver] 一致：先把旧项从
  /// [oldIndex] 移除，再插入到 [newIndex]。
  final void Function(int oldIndex, int newIndex) onReorder;

  /// 横向列数。
  final int crossAxisCount;

  /// 主轴（纵向）间距。
  final double mainAxisSpacing;

  /// 交叉轴（横向）列间距。
  final double crossAxisSpacing;

  @override
  State<ReorderableMasonrySliver> createState() =>
      _ReorderableMasonrySliverState();
}

class _ReorderableMasonrySliverState extends State<ReorderableMasonrySliver> {
  /// 记录每个位置真实子项的全局位置，用于计算拖拽落点对应的目标索引。
  ///
  /// 该 key 挂在真实子项上。拖拽期间，被拖拽项的子项被替换为占位卡（其 key
  /// 变为 null），其余所有子项仍持有效 context，因此 [currentContext] 可用于
  /// 计算落点相对最近目标的插入位置。
  final List<GlobalKey> _tileKeys = [];

  @override
  Widget build(BuildContext context) {
    // 让 [GlobalKey] 集合与 itemCount 长度保持一致。
    while (_tileKeys.length < widget.itemCount) {
      _tileKeys.add(GlobalKey());
    }
    if (_tileKeys.length > widget.itemCount) {
      _tileKeys.removeRange(widget.itemCount, _tileKeys.length);
    }

    return SliverMasonryGrid.count(
      crossAxisCount: widget.crossAxisCount,
      mainAxisSpacing: widget.mainAxisSpacing,
      crossAxisSpacing: widget.crossAxisSpacing,
      childCount: widget.itemCount,
      itemBuilder: (context, index) => _buildTile(context, index),
    );
  }

  Widget _buildTile(BuildContext context, int index) {
    if (widget.itemCount == 1) {
      return widget.itemBuilder(context, index);
    }

    // 只构建一次真实子项。拖拽期间 DragTarget 的重建都复用此实例，
    // 不会反复调用 itemBuilder，从而避免复杂卡片被无限重建导致卡死。
    final child = widget.itemBuilder(context, index);

    return LongPressDraggable<int>(
      data: index,
      hapticFeedbackOnStart: true,
      // 与竖屏一致：长按后拖动。反馈卡渲染在 Overlay 中，仅作视觉
      // 提示，不重建真实子项。
      feedback: widget.feedbackBuilder?.call(context, index) ??
          _DragFeedbackCard(label: '卡片 ${index + 1}'),
      // 拖拽占位也使用轻量占位，避免替换掉 TextField/Provider 的真实子项。
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: widget.placeholderBuilder?.call(context, index) ??
            const SizedBox(height: 120),
      ),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != index,
        onAcceptWithDetails: (details) =>
            _handleDrop(details.data, details.offset),
        builder: (context, candidates, rejected) => KeyedSubtree(
          key: _tileKeys[index],
          child: child,
        ),
      ),
    );
  }

  void _handleDrop(int oldIndex, Offset dropGlobal) {
    if (oldIndex < 0 || oldIndex >= widget.itemCount) return;

    // 依据各真实子项当前中心与落点的距离，找到最近的作为插入锚点。
    int bestIndex = -1;
    double bestDistance = double.infinity;
    Offset? bestCenter;
    for (var i = 0; i < widget.itemCount; i++) {
      final ctx = _tileKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      final center = rect.center;
      final distance = (center - dropGlobal).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
        bestCenter = center;
      }
    }
    if (bestIndex < 0 || bestCenter == null) return;

    // 落点在锚点中心下方则插入到其后，否则插入到其前。
    int newIndex = dropGlobal.dy > bestCenter.dy ? bestIndex + 1 : bestIndex;
    newIndex = newIndex.clamp(0, widget.itemCount);

    if (oldIndex == newIndex) {
      return;
    }
    widget.onReorder(oldIndex, newIndex);
  }
}

/// 拖拽时跟随指针的轻量反馈卡，仅作视觉提示，不包含任何真实子项。
class _DragFeedbackCard extends StatelessWidget {
  const _DragFeedbackCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 160,
        height: 60,
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ),
    );
  }
}