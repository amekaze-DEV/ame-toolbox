import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/todo_category.dart';
import '../providers/todo_config_provider.dart';

/// 候选分类颜色（取自 Material 调色板，避免硬编码主题色）。
const _presetColors = <int>[
  0xFF1565C0, // 蓝
  0xFF2D7D46, // 绿
  0xFF6A1B9A, // 紫
  0xFFC62828, // 红
  0xFFEF6C00, // 橙
  0xFF00838F, // 青
  0xFF5D4037, // 棕
  0xFF455A64, // 蓝灰
];

/// 分类管理器：新增、编辑、删除、排序分类。
class TodoCategoryManager extends ConsumerWidget {
  const TodoCategoryManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(todoConfigProvider);
    final categories = config.config.categories;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('分类管理', style: textTheme.titleSmall),
            const Spacer(),
            AdaptiveButton(
              variant: AdaptiveButtonVariant.outlined,
              icon: Icons.add,
              label: '新增分类',
              onPressed: () => _openEditor(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (categories.isEmpty)
          Text(
            '暂无自定义分类',
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            onReorderItem: (oldIndex, newIndex) =>
                ref.read(todoConfigProvider).reorderCategories(oldIndex, newIndex),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                key: ValueKey(category.id),
                leading: CircleAvatar(
                  backgroundColor: Color(category.colorValue),
                  radius: 10,
                ),
                title: Text(category.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AdaptiveIconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: '编辑',
                      onPressed: () => _openEditor(context, ref, category: category),
                    ),
                    AdaptiveIconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: '删除',
                      onPressed: () => _confirmDelete(context, ref, category),
                    ),
                    const Icon(Icons.drag_handle, color: Colors.grey),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    TodoCategory? category,
  }) async {
    final result = await showDialog<({String name, int color})>(
      context: context,
      builder: (_) => _CategoryEditorDialog(category: category),
    );
    if (result == null) return;

    final controller = ref.read(todoConfigProvider);
    if (category == null) {
      await controller.addCategory(result.name, colorValue: result.color);
    } else {
      await controller.updateCategory(
        category.copyWith(name: result.name, colorValue: result.color),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TodoCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除分类'),
        content: Text('确定删除分类"${category.name}"吗？该分类下的待办将变为无分类。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(todoConfigProvider).deleteCategory(category.id);
    }
  }
}

/// 分类新增/编辑对话框。
class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({this.category});

  final TodoCategory? category;

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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
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
                              color: Theme.of(context).colorScheme.primary,
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop((name: name, color: _color));
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}