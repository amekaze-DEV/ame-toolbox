import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';
import 'package:ametoolbox/shared/widgets/adaptive_list_tile.dart';

import '../models/note_category.dart';
import '../providers/sticky_notes_config_provider.dart';
import '../providers/sticky_notes_provider.dart';

/// 候选分类颜色（18 色，取自 Material 调色板，6 列排布）。
const _presetColors = <int>[
  0xFF1565C0, // 蓝
  0xFF2D7D46, // 绿
  0xFF6A1B9A, // 紫
  0xFF00897B, // 青
  0xFFC62828, // 红
  0xFFEF6C00, // 橙
  0xFFAD1457, // 玫红
  0xFF4527A0, // 深紫
  0xFF283593, // 靛蓝
  0xFF0277BD, // 浅蓝
  0xFF00838F, // 蓝绿
  0xFF558B2F, // 草绿
  0xFF9E9D24, // 橄榄
  0xFFF9A825, // 黄
  0xFFD84315, // 深橙
  0xFF4E342E, // 棕
  0xFF37474F, // 蓝灰
  0xFF424242, // 灰
];

/// 分类管理器：新增、编辑、删除、排序分类（spec §3.4 / §4.2）。
class NoteCategoryManager extends ConsumerWidget {
  const NoteCategoryManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(stickyNotesConfigProvider).config.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: AdaptiveButton(
            variant: AdaptiveButtonVariant.outlined,
            icon: Icons.add,
            label: '新增分类',
            onPressed: () => _openEditor(context, ref),
          ),
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          // onReorderItem 已按移除后位置调整 newIndex（Flutter 3.41+ 推荐）。
          onReorderItem: (oldIndex, newIndex) => ref
              .read(stickyNotesConfigProvider)
              .reorderCategories(oldIndex, newIndex),
          itemBuilder: (context, index) {
            final category = categories[index];
            return AdaptiveListTile(
              key: ValueKey(category.id),
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(category.colorValue),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(category.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdaptiveIconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: '编辑分类',
                    onPressed: () =>
                        _openEditor(context, ref, category: category),
                  ),
                  AdaptiveIconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: '删除分类',
                    onPressed: () => _confirmDelete(context, ref, category),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// 打开新增 / 编辑分类对话框。
  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    NoteCategory? category,
  }) async {
    final target = category;
    final result = await showDialog<({String name, int color})>(
      context: context,
      builder: (_) => _CategoryEditorDialog(
        category: target,
        // 编辑既有分类时提供删除入口（新增分类无删除）。
        onDelete: target == null
            ? null
            : () => _confirmDelete(context, ref, target),
      ),
    );
    if (result == null) return;

    final controller = ref.read(stickyNotesConfigProvider);
    if (category == null) {
      await controller.addCategory(result.name, colorValue: result.color);
    } else {
      await controller.updateCategory(
        category.copyWith(name: result.name, colorValue: result.color),
      );
    }
  }

  /// 删除分类确认；返回是否已删除。确认后同时将分类下便签置为无分类（spec §4.2）。
  Future<bool> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    NoteCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('删除分类'),
        content: Text('确定删除分类"${category.name}"吗？该分类下的便签将变为无分类。'),
        actions: [
          AdaptiveButton(
            variant: AdaptiveButtonVariant.text,
            label: '取消',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AdaptiveButton(
            variant: AdaptiveButtonVariant.filled,
            label: '删除',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    await ref.read(stickyNotesConfigProvider).deleteCategory(category.id);
    await ref.read(stickyNotesProvider).clearCategory(category.id);
    return true;
  }
}

/// 分类新增 / 编辑对话框。
class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({this.category, this.onDelete});

  final NoteCategory? category;

  /// 删除当前分类（返回是否已删除）；为 null 时不展示删除入口。
  final Future<bool> Function()? onDelete;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _nameController;
  late int _color;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _color = widget.category?.colorValue ?? _presetColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 请求删除当前分类；确认删除成功后关闭编辑对话框。
  Future<void> _handleDelete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) return;
    final deleted = await onDelete();
    if (!mounted || !deleted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(widget.category == null ? '新增分类' : '编辑分类'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '分类名称',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('颜色', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _presetColors)
                InkWell(
                  key: ValueKey(c),
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: _color == c
                          ? Border.all(
                              color: colorScheme.primary,
                              width: 3,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (widget.onDelete != null)
          AdaptiveButton(
            variant: AdaptiveButtonVariant.text,
            icon: Icons.delete_outline,
            label: '删除',
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            onPressed: _handleDelete,
          ),
        AdaptiveButton(
          variant: AdaptiveButtonVariant.text,
          label: '取消',
          onPressed: () => Navigator.of(context).pop(),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _nameController,
          builder: (context, value, _) {
            final name = value.text.trim();
            return AdaptiveButton(
              variant: AdaptiveButtonVariant.filled,
              label: '确定',
              onPressed: name.isEmpty
                  ? null
                  : () =>
                      Navigator.of(context).pop((name: name, color: _color)),
            );
          },
        ),
      ],
    );
  }
}