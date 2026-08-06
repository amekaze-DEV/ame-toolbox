import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';
import 'package:ametoolbox/shared/widgets/adaptive_list_tile.dart';

import '../models/shift_config.dart';
import '../providers/holiday_data_controller.dart';
import '../providers/holiday_data_provider.dart';
import '../providers/shift_config_controller.dart';
import '../providers/shift_config_provider.dart';
import '../utils/date_utils.dart';

/// 倒班助手设置页。
///
/// 提供轮班管理、轮班详情编辑、主要轮班设置与节假日手动更新。
class ShiftAssistantSettingsPage extends ConsumerWidget {
  const ShiftAssistantSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configController = ref.watch(shiftConfigProvider);
    final configNotifier = ref.read(shiftConfigProvider.notifier);
    final holidayController = ref.watch(holidayDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(
            title: '轮班管理',
            actionLabel: '添加',
            onAction: () => _showAddRotationDialog(context, configNotifier),
          ),
          const SizedBox(height: 8),
          _RotationList(
            config: configController.config,
            onSetPrimary: configNotifier.setPrimaryRotation,
            onEdit: (rotation) => _showEditRotationDialog(
              context,
              configNotifier,
              rotation,
            ),
            onDelete: configNotifier.deleteRotation,
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: '节假日数据',
            actionLabel: holidayController.isUpdating ? '更新中' : '立即更新',
            onAction: holidayController.isUpdating
                ? null
                : () => holidayController.update(),
          ),
          const SizedBox(height: 8),
          _HolidayStatus(controller: holidayController),
        ],
      ),
    );
  }

  Future<void> _showAddRotationDialog(
    BuildContext context,
    ShiftConfigController notifier,
  ) async {
    final result = await showDialog<_RotationFormResult>(
      context: context,
      builder: (context) => const _RotationFormDialog(),
    );
    if (result == null) return;
    await notifier.addRotationFromTemplate(
      templateId: result.templateId,
      name: result.name,
      isPrimary: result.isPrimary,
    );
  }

  Future<void> _showEditRotationDialog(
    BuildContext context,
    ShiftConfigController notifier,
    ShiftRotation rotation,
  ) async {
    final result = await showDialog<_RotationEditResult>(
      context: context,
      builder: (context) => _RotationEditDialog(rotation: rotation),
    );
    if (result == null) return;

    var updated = rotation.copyWith(
      name: result.name,
      baseDate: result.baseDate,
      cycleCount: result.cycleCount,
      groups: result.groups,
      slots: result.slots,
      assignments: result.assignments,
    );

    await notifier.updateRotation(updated);
  }
}

/// 分组标题 + 操作按钮。
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        AdaptiveButton(
          onPressed: onAction,
          label: actionLabel,
          variant: AdaptiveButtonVariant.text,
        ),
      ],
    );
  }
}

/// 轮班列表。
class _RotationList extends StatelessWidget {
  const _RotationList({
    required this.config,
    required this.onSetPrimary,
    required this.onEdit,
    required this.onDelete,
  });

  final ShiftConfig config;
  final ValueChanged<String> onSetPrimary;
  final ValueChanged<ShiftRotation> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final rotations = config.orderedRotations;
    if (rotations.isEmpty) {
      return const _EmptyHint(text: '暂无轮班，点击右上角添加');
    }

    return Card(
      child: Column(
        children: rotations.map((rotation) {
          return AdaptiveListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                rotation.name.isEmpty ? '' : rotation.name[0],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            title: Text(rotation.name),
            subtitle: Text(
              '${rotation.groups.length}个班组 · ${rotation.slots.length}种状态 · '
              '${rotation.cycleCount}循环 · ${rotation.cycleDays}天周期',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdaptiveIconButton(
                  icon: Icon(
                    rotation.isPrimary ? Icons.star : Icons.star_border,
                  ),
                  tooltip:
                      rotation.isPrimary ? '主要轮班' : '设为主要轮班',
                  onPressed: rotation.isPrimary
                      ? null
                      : () => onSetPrimary(rotation.id),
                ),
                AdaptiveIconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: '编辑',
                  onPressed: () => onEdit(rotation),
                ),
                AdaptiveIconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: '删除',
                  onPressed: () => onDelete(rotation.id),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 节假日状态卡片。
class _HolidayStatus extends StatelessWidget {
  const _HolidayStatus({required this.controller});

  final HolidayDataController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final lastUpdated = controller.lastUpdated;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lastUpdated == null
                  ? '尚未更新节假日数据'
                  : '上次更新：${_formatDateTime(lastUpdated)}',
              style: textTheme.bodyMedium,
            ),
            if (controller.lastError != null) ...[
              const SizedBox(height: 8),
              Text(
                '最近一次更新失败：${controller.lastError}',
                style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${_two(date.month)}-${_two(date.day)} '
        '${_two(date.hour)}:${_two(date.minute)}';
  }

  String _two(int n) => n >= 10 ? '$n' : '0$n';
}

/// 空状态提示。
class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

/// 添加轮班表单结果。
class _RotationFormResult {
  const _RotationFormResult({
    required this.templateId,
    required this.name,
    required this.isPrimary,
  });

  final String templateId;
  final String name;
  final bool isPrimary;
}

/// 添加轮班对话框。
class _RotationFormDialog extends StatefulWidget {
  const _RotationFormDialog();

  @override
  State<_RotationFormDialog> createState() => _RotationFormDialogState();
}

class _RotationFormDialogState extends State<_RotationFormDialog> {
  late final TextEditingController _nameController;
  late String _templateId;
  bool _isPrimary = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _templateId = ShiftRotationTemplate.all.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = ShiftRotationTemplate.all;

    return AlertDialog(
      title: const Text('添加轮班'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '轮班名称',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _templateId,
              decoration: const InputDecoration(
                labelText: '选择模板',
                border: OutlineInputBorder(),
              ),
              items: templates.map((template) {
                return DropdownMenuItem(
                  value: template.id,
                  child: Text(template.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _templateId = value);
              },
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _isPrimary,
              onChanged: (value) {
                setState(() => _isPrimary = value ?? false);
              },
              title: const Text('设为主要轮班'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        AdaptiveButton(
          onPressed: () => Navigator.of(context).pop(),
          label: '取消',
          variant: AdaptiveButtonVariant.text,
        ),
        AdaptiveButton(
          onPressed: _nameController.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(
                    _RotationFormResult(
                      templateId: _templateId,
                      name: _nameController.text.trim(),
                      isPrimary: _isPrimary,
                    ),
                  ),
          label: '保存',
          variant: AdaptiveButtonVariant.text,
        ),
      ],
    );
  }
}

/// 编辑轮班结果。
class _RotationEditResult {
  const _RotationEditResult({
    required this.name,
    required this.baseDate,
    required this.cycleCount,
    required this.groups,
    required this.slots,
    required this.assignments,
  });

  final String name;
  final DateTime baseDate;
  final int cycleCount;
  final List<ShiftGroup> groups;
  final List<ShiftSlot> slots;
  final List<List<int>> assignments;
}

/// 编辑轮班对话框。
class _RotationEditDialog extends StatefulWidget {
  const _RotationEditDialog({required this.rotation});

  final ShiftRotation rotation;

  @override
  State<_RotationEditDialog> createState() => _RotationEditDialogState();
}

class _RotationEditDialogState extends State<_RotationEditDialog> {
  late final TextEditingController _nameController;
  late DateTime _baseDate;
  late int _cycleCount;
  late List<ShiftGroup> _groups;
  late List<ShiftSlot> _slots;
  late List<List<int>> _assignments;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rotation.name);
    _baseDate = widget.rotation.baseDate;
    _cycleCount = widget.rotation.cycleCount;
    _groups = List.of(widget.rotation.groups);
    _slots = List.of(widget.rotation.slots);
    _assignments = widget.rotation.assignments
        .map((row) => List<int>.of(row))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑轮班'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '轮班名称',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildCycleCountEditor(),
              const SizedBox(height: 24),
              Text(
                '班组名称',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildGroupEditors(),
              const SizedBox(height: 24),
              Text(
                '轮班状态',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildSlotEditors(),
              const SizedBox(height: 24),
              Text(
                '周期安排（行=班组，列=周期内第几天）',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildAssignmentMatrix(),
            ],
          ),
        ),
      ),
      actions: [
        AdaptiveButton(
          onPressed: () => Navigator.of(context).pop(),
          label: '取消',
          variant: AdaptiveButtonVariant.text,
        ),
        AdaptiveButton(
          onPressed: _nameController.text.trim().isEmpty ? null : _save,
          label: '保存',
          variant: AdaptiveButtonVariant.text,
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _baseDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _baseDate = dateOnly(picked));
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '周期起始日期',
          border: OutlineInputBorder(),
        ),
        child: Text('${_baseDate.year}-${_two(_baseDate.month)}-${_two(_baseDate.day)}'),
      ),
    );
  }

  Widget _buildCycleCountEditor() {
    return Row(
      children: [
        Text('循环数：', style: Theme.of(context).textTheme.bodyMedium),
        IconButton(
          onPressed: _cycleCount > 1
              ? () => _updateCycleCount(_cycleCount - 1)
              : null,
          icon: const Icon(Icons.remove),
        ),
        Text('$_cycleCount'),
        IconButton(
          onPressed: () => _updateCycleCount(_cycleCount + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  void _updateCycleCount(int value) {
    if (value < 1 || value == _cycleCount) return;
    setState(() {
      _cycleCount = value;
      _resizeAssignments();
    });
  }

  /// 根据当前班组数和循环数调整分配矩阵长度，新增列按原周期重复填充。
  void _resizeAssignments() {
    final newLength = _groups.length * _cycleCount;
    for (var i = 0; i < _assignments.length; i++) {
      final oldRow = _assignments[i];
      _assignments[i] = List<int>.generate(
        newLength,
        (dayIndex) => dayIndex < oldRow.length
            ? oldRow[dayIndex]
            : oldRow[dayIndex % oldRow.length],
      );
    }
  }

  Widget _buildGroupEditors() {
    return Column(
      children: [
        for (var i = 0; i < _groups.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              decoration: InputDecoration(
                labelText: '班组 ${i + 1}',
                border: const OutlineInputBorder(),
              ),
              controller: TextEditingController(text: _groups[i].name),
              onChanged: (value) {
                _groups[i] = _groups[i].copyWith(name: value);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSlotEditors() {
    return Column(
      children: [
        for (var i = 0; i < _slots.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              decoration: InputDecoration(
                labelText: '状态 ${i + 1}',
                border: const OutlineInputBorder(),
              ),
              controller: TextEditingController(text: _slots[i].name),
              onChanged: (value) {
                _slots[i] = _slots[i].copyWith(name: value);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAssignmentMatrix() {
    final cycleDays = _groups.length * _cycleCount;
    const dayCellWidth = 64.0;
    const labelWidth = 72.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 表头：第几天
          Row(
            children: [
              const SizedBox(width: labelWidth),
              for (var day = 0; day < cycleDays; day++)
                SizedBox(
                  width: dayCellWidth,
                  child: Text(
                    'D${day + 1}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
          // 每行：班组 + 每天的状态下拉
          for (var groupIndex = 0; groupIndex < _groups.length; groupIndex++)
            Row(
              children: [
                SizedBox(
                  width: labelWidth,
                  child: Text(
                    _groups[groupIndex].name,
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                for (var dayIndex = 0; dayIndex < cycleDays; dayIndex++)
                  SizedBox(
                    width: dayCellWidth,
                    child: DropdownButtonFormField<int>(
                      isDense: true,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 4),
                        border: InputBorder.none,
                      ),
                      initialValue: _assignments[groupIndex][dayIndex],
                      items: List.generate(_slots.length, (slotIndex) {
                        return DropdownMenuItem(
                          value: slotIndex,
                          child: Text(
                            _slots[slotIndex].name,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _assignments[groupIndex][dayIndex] = value;
                        });
                      },
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _save() {
    Navigator.of(context).pop(
      _RotationEditResult(
        name: _nameController.text.trim(),
        baseDate: _baseDate,
        cycleCount: _cycleCount,
        groups: _groups,
        slots: _slots,
        assignments: _assignments,
      ),
    );
  }

  String _two(int n) => n >= 10 ? '$n' : '0$n';
}
