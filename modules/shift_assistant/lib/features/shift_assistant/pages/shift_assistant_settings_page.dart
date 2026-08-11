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
            onEdit: (rotation) => _showEditRotationDialog(
              context,
              configNotifier,
              rotation,
            ),
            onDelete: configNotifier.deleteRotation,
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: '我的班组',
            actionLabel: '设置',
            onAction: configController.config.rotations.isEmpty
                ? null
                : () => _showMyTeamDialog(context, configNotifier),
          ),
          const SizedBox(height: 8),
          _MyTeamCard(config: configController.config),
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
    final result = await showDialog<_RotationConfigResult>(
      context: context,
      builder: (context) => const _RotationConfigDialog(title: '添加轮班'),
    );
    if (result == null) return;
    await notifier.addRotation(
      name: result.name,
      baseDate: result.baseDate,
      cycleDays: result.cycleDays,
      groups: result.groups,
      slots: result.slots,
      assignments: result.assignments,
    );
  }

  Future<void> _showEditRotationDialog(
    BuildContext context,
    ShiftConfigController notifier,
    ShiftRotation rotation,
  ) async {
    final result = await showDialog<_RotationConfigResult>(
      context: context,
      builder: (context) => _RotationConfigDialog(
        title: '编辑轮班',
        initialRotation: rotation,
      ),
    );
    if (result == null) return;

    final updated = rotation.copyWith(
      name: result.name,
      baseDate: result.baseDate,
      cycleDays: result.cycleDays,
      groups: result.groups,
      slots: result.slots,
      assignments: result.assignments,
    );

    await notifier.updateRotation(updated);
  }

  Future<void> _showMyTeamDialog(
    BuildContext context,
    ShiftConfigController notifier,
  ) async {
    final result = await showDialog<_MyTeamResult>(
      context: context,
      builder: (context) => _MyTeamDialog(config: notifier.config),
    );
    if (result == null) return;

    if (result.clear) {
      await notifier.clearMyTeam();
    } else {
      await notifier.setMyTeam(result.rotationId, result.groupId);
    }
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
    required this.onEdit,
    required this.onDelete,
  });

  final ShiftConfig config;
  final ValueChanged<ShiftRotation> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final rotations = config.rotations;
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
              '${rotation.cycleDays}天周期',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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

/// 我的班组状态卡片。
class _MyTeamCard extends StatelessWidget {
  const _MyTeamCard({required this.config});

  final ShiftConfig config;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final team = config.myTeamGroup;

    final rotation = team == null
        ? null
        : config.findRotationById(config.myTeamRotationId!);

    final String title;
    final IconData icon;
    if (team == null) {
      title = '未设置我的班组';
      icon = Icons.person_outline;
    } else {
      title = '${rotation?.name ?? '未知轮班'} · ${team.name}';
      icon = Icons.person;
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(title, style: textTheme.bodyLarge),
      ),
    );
  }
}

/// 「设置我的班组」对话框的结果。
class _MyTeamResult {
  const _MyTeamResult({this.rotationId, this.groupId, this.clear = false});

  /// 选中的轮班 ID。
  final String? rotationId;

  /// 选中的班组 ID。
  final String? groupId;

  /// 为 true 表示用户选择清除我的班组。
  final bool clear;
}

/// 「设置我的班组」对话框：选择轮班与其中的班组，或选择不设置。
class _MyTeamDialog extends StatefulWidget {
  const _MyTeamDialog({required this.config});

  final ShiftConfig config;

  @override
  State<_MyTeamDialog> createState() => _MyTeamDialogState();
}

class _MyTeamDialogState extends State<_MyTeamDialog> {
  late String? _rotationId;
  late String? _groupId;

  @override
  void initState() {
    super.initState();
    _rotationId = widget.config.myTeamRotationId;
    // 若当前设置引用失效，则回退到第一个轮班。
    if (_rotationId == null ||
        widget.config.findRotationById(_rotationId!) == null) {
      _rotationId =
          widget.config.rotations.isEmpty ? null : widget.config.rotations.first.id;
    }
    _groupId = widget.config.myTeamGroupId;
    if (_groupId != null && _groupsOf(_rotationId).every((g) => g.id != _groupId)) {
      _groupId = null;
    }
  }

  List<ShiftGroup> _groupsOf(String? rotationId) {
    final rotation =
        rotationId == null ? null : widget.config.findRotationById(rotationId);
    return rotation?.groups ?? const [];
  }

  bool get _hasSelection => _rotationId != null && _groupId != null;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groups = _groupsOf(_rotationId);

    return AlertDialog(
      title: const Text('设置我的班组'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('选择轮班', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _rotationId,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: widget.config.rotations.map((r) {
                return DropdownMenuItem(
                  value: r.id,
                  child: Text(
                    r.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _rotationId = value;
                  _groupId = null;
                });
              },
            ),
            const SizedBox(height: 16),
            Text('选择班组', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _groupId,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              hint: const Text('选择班组'),
              items: groups.map((g) {
                return DropdownMenuItem(
                  value: g.id,
                  child: Text(g.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) => setState(() => _groupId = value),
            ),
            const SizedBox(height: 8),
            if (_hasSelection)
              Text(
                '已选择：${groups.firstWhere((g) => g.id == _groupId).name}',
                style: textTheme.bodySmall,
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
        if (_hasSelection)
          AdaptiveButton(
            onPressed: () => Navigator.of(context).pop(
              _MyTeamResult(
                rotationId: _rotationId,
                groupId: _groupId,
              ),
            ),
            label: '保存',
            variant: AdaptiveButtonVariant.text,
          ),
        AdaptiveButton(
          onPressed: () => Navigator.of(context).pop(
            const _MyTeamResult(clear: true),
          ),
          label: '清除',
          variant: AdaptiveButtonVariant.text,
        ),
      ],
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

/// 添加 / 编辑轮班对话框的统一结果。
class _RotationConfigResult {
  const _RotationConfigResult({
    required this.name,
    required this.baseDate,
    required this.cycleDays,
    required this.groups,
    required this.slots,
    required this.assignments,
  });

  final String name;
  final DateTime baseDate;
  final int cycleDays;
  final List<ShiftGroup> groups;
  final List<ShiftSlot> slots;
  final List<List<int>> assignments;
}

/// 添加 / 编辑轮班统一对话框。
///
/// 在添加与编辑时均可完整设置：轮班名称、起始日期、循环周期天数、
/// 班组（可增删、改名）、轮班状态（可增删、改名）以及周期安排矩阵，
/// 保证两种场景功能一致。
class _RotationConfigDialog extends StatefulWidget {
  const _RotationConfigDialog({
    required this.title,
    this.initialRotation,
  });

  final String title;
  final ShiftRotation? initialRotation;

  @override
  State<_RotationConfigDialog> createState() => _RotationConfigDialogState();
}

class _RotationConfigDialogState extends State<_RotationConfigDialog> {
  late final TextEditingController _nameController;
  late final List<TextEditingController> _groupControllers;
  late final List<TextEditingController> _slotControllers;
  late final List<String> _groupIds;
  late DateTime _baseDate;
  late int _cycleDays;
  late List<List<int>> _assignments;
  int _groupSeq = 0;

  @override
  void initState() {
    super.initState();
    final rotation = widget.initialRotation;

    _nameController = TextEditingController(text: rotation?.name ?? '我的轮班');
    _baseDate = rotation?.baseDate ?? dateOnly(DateTime.now());
    _cycleDays = rotation?.cycleDays ?? 4;

    if (rotation != null) {
      _groupControllers = rotation.groups
          .map((g) => TextEditingController(text: g.name))
          .toList();
      _groupIds = rotation.groups.map((g) => g.id).toList();
      _slotControllers = rotation.slots
          .map((s) => TextEditingController(text: s.name))
          .toList();
      _assignments = rotation.assignments
          .map((row) => List<int>.of(row))
          .toList();
      _groupSeq = rotation.groups.length;
    } else {
      _groupControllers =
          List.generate(4, (i) => TextEditingController(text: '${i + 1}班'));
      _groupIds = List.generate(4, _newGroupKey);
      _slotControllers = [
        TextEditingController(text: '白班'),
        TextEditingController(text: '夜班'),
        TextEditingController(text: '休息'),
      ];
      _assignments = List.generate(
        4,
        (g) => List.generate(_cycleDays, (d) => (g + d) % 3),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _groupControllers) {
      c.dispose();
    }
    for (final c in _slotControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _newGroupKey([int? index]) {
    final seq = index ?? _groupSeq++;
    return 'group_${DateTime.now().millisecondsSinceEpoch}_$seq';
  }

  List<ShiftGroup> get _groups => List.generate(
        _groupControllers.length,
        (i) => ShiftGroup(
          id: _groupIds[i],
          name: _groupControllers[i].text.trim(),
        ),
      );

  List<ShiftSlot> get _slots => List.generate(
        _slotControllers.length,
        (i) => ShiftSlot(name: _slotControllers[i].text.trim()),
      );

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      _slotControllers.any((c) => c.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(widget.title),
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
              _buildCycleDaysEditor(),
              const SizedBox(height: 24),
              Text('班组名称', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              _buildGroupEditors(),
              const SizedBox(height: 24),
              Text('轮班状态', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              _buildSlotEditors(),
              const SizedBox(height: 24),
              Text(
                '周期安排（行=班组，列=周期内第几天）',
                style: textTheme.titleSmall,
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
          onPressed: _canSave ? _save : null,
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
          labelText: '轮班起始日期',
          border: OutlineInputBorder(),
        ),
        child: Text(
          '${_baseDate.year}-${_two(_baseDate.month)}-${_two(_baseDate.day)}',
        ),
      ),
    );
  }

  Widget _buildCycleDaysEditor() {
    return Row(
      children: [
        Text('循环周期天数：', style: Theme.of(context).textTheme.bodyMedium),
        IconButton(
          onPressed: _cycleDays > ShiftRotation.minCycleDays
              ? () => _updateCycleDays(_cycleDays - 1)
              : null,
          icon: const Icon(Icons.remove),
        ),
        Text('$_cycleDays'),
        IconButton(
          onPressed: _cycleDays < ShiftRotation.maxCycleDays
              ? () => _updateCycleDays(_cycleDays + 1)
              : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  void _updateCycleDays(int value) {
    final newDays = value.clamp(
      ShiftRotation.minCycleDays,
      ShiftRotation.maxCycleDays,
    );
    if (newDays == _cycleDays) return;

    setState(() {
      _cycleDays = newDays;
      for (var i = 0; i < _assignments.length; i++) {
        final oldRow = _assignments[i];
        _assignments[i] = List<int>.generate(
          _cycleDays,
          (dayIndex) => dayIndex < oldRow.length
              ? oldRow[dayIndex]
              : oldRow[dayIndex % oldRow.length],
        );
      }
    });
  }

  Widget _buildGroupEditors() {
    return Column(
      children: [
        for (var i = 0; i < _groupControllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _groupControllers[i],
                    decoration: InputDecoration(
                      labelText: '班组 ${i + 1}',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 1,
                  ),
                ),
                if (_groupControllers.length > 1)
                  AdaptiveIconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: '删除班组',
                    onPressed: () => _removeGroup(i),
                  ),
              ],
            ),
          ),
        AdaptiveButton(
          onPressed: _groupControllers.length < ShiftRotation.maxGroupCount
              ? _addGroup
              : null,
          label: '添加班组',
          variant: AdaptiveButtonVariant.text,
        ),
      ],
    );
  }

  void _addGroup() {
    if (_groupControllers.length >= ShiftRotation.maxGroupCount) return;
    final index = _groupControllers.length;

    setState(() {
      _groupControllers.add(TextEditingController(text: '${index + 1}班'));
      _groupIds.add(_newGroupKey());
      _assignments.add(
        List.generate(
          _cycleDays,
          (dayIndex) => (index + dayIndex) % _slotControllers.length,
        ),
      );
    });
  }

  void _removeGroup(int index) {
    if (_groupControllers.length <= ShiftRotation.minGroupCount ||
        index < 0 ||
        index >= _groupControllers.length) {
      return;
    }

    setState(() {
      _groupControllers.removeAt(index).dispose();
      _groupIds.removeAt(index);
      _assignments.removeAt(index);
    });
  }

  Widget _buildSlotEditors() {
    return Column(
      children: [
        for (var i = 0; i < _slotControllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _slotControllers[i],
                    decoration: InputDecoration(
                      labelText: '状态 ${i + 1}',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 1,
                  ),
                ),
                if (_slotControllers.length > 1)
                  AdaptiveIconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: '删除状态',
                    onPressed: () => _removeSlot(i),
                  ),
              ],
            ),
          ),
        AdaptiveButton(
          onPressed: _addSlot,
          label: '添加状态',
          variant: AdaptiveButtonVariant.text,
        ),
      ],
    );
  }

  void _addSlot() {
    setState(() => _slotControllers.add(TextEditingController(text: '')));
  }

  void _removeSlot(int index) {
    if (_slotControllers.length <= 1 ||
        index < 0 ||
        index >= _slotControllers.length) {
      return;
    }

    setState(() {
      _slotControllers.removeAt(index).dispose();
      // 同步分配矩阵：被删除状态引用归零，大于该索引的引用前移。
      for (var groupIndex = 0; groupIndex < _assignments.length; groupIndex++) {
        _assignments[groupIndex] = _assignments[groupIndex].map((slotIndex) {
          if (slotIndex == index) return 0;
          if (slotIndex > index) return slotIndex - 1;
          return slotIndex;
        }).toList();
      }
    });
  }

  Widget _buildAssignmentMatrix() {
    const dayCellWidth = 64.0;
    const labelWidth = 72.0;
    final slotNames = _slotControllers.map((c) => c.text.trim()).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 表头：第几天
          Row(
            children: [
              const SizedBox(width: labelWidth),
              for (var day = 0; day < _cycleDays; day++)
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
          for (var groupIndex = 0; groupIndex < _groupControllers.length;
              groupIndex++)
            Row(
              children: [
                SizedBox(
                  width: labelWidth,
                  child: Text(
                    _groupControllers[groupIndex].text,
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                for (var dayIndex = 0; dayIndex < _cycleDays; dayIndex++)
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
                      items: List.generate(slotNames.length, (slotIndex) {
                        return DropdownMenuItem(
                          value: slotIndex,
                          child: Text(
                            slotNames[slotIndex],
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
      _RotationConfigResult(
        name: _nameController.text.trim(),
        baseDate: _baseDate,
        cycleDays: _cycleDays,
        groups: _groups,
        slots: _slots,
        assignments: _assignments,
      ),
    );
  }

  String _two(int n) => n >= 10 ? '$n' : '0$n';
}
