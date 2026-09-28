import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/note_category.dart';
import '../services/note_query_service.dart';

/// 分类筛选条（spec §3.2）。
///
/// 横向滚动：全部 / 各分类 / 无分类；点击切换筛选。
class NoteCategoryFilter extends StatelessWidget {
  const NoteCategoryFilter({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  /// 分类列表（按 displayOrder 排序）。
  final List<NoteCategory> categories;

  /// 当前选中筛选（null = 全部；[NoteQueryService.noCategoryKey] = 无分类）。
  final String? selectedId;

  /// 选中回调（null 表示全部）。
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ScrollConfiguration(
        // 支持鼠标拖动与滚轮横向滚动（桌面端）。
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.stylus,
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          children: [
            _buildChip(
              context,
              label: '全部',
              selected: selectedId == null,
              color: null,
              onTap: () => onSelected(null),
            ),
            for (final category in categories)
              _buildChip(
                context,
                label: category.name,
                selected: selectedId == category.id,
                color: Color(category.colorValue),
                onTap: () => onSelected(category.id),
              ),
            _buildChip(
              context,
              label: '无分类',
              selected: selectedId == NoteQueryService.noCategoryKey,
              color: null,
              onTap: () => onSelected(NoteQueryService.noCategoryKey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required Color? color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: textTheme.labelLarge),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        selectedColor: colorScheme.secondaryContainer,
        avatar: color == null
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
      ),
    );
  }
}
