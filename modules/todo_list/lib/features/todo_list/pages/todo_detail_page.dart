import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/providers/file_provider.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';
import 'package:ametoolbox/shared/widgets/md3_switch.dart';

import '../models/todo_image_attachment.dart';
import '../models/todo_item.dart';
import '../models/todo_priority.dart';
import '../models/recurrence_rule.dart';
import '../providers/todo_config_provider.dart';
import '../providers/todo_list_provider.dart';
import '../widgets/recurrence_rule_editor.dart';
import '../widgets/todo_image_attachments_editor.dart';
import '../widgets/todo_priority_selector.dart';

/// 待办详情 / 新增编辑页（P6）。
///
/// 支持：名称、详情文本、图片附件、5 级优先级、期限、循环规则（多规则 + 五级菜单）、
/// 起止时间、提前提醒。空名称拦截，不允许保存。
class TodoDetailPage extends ConsumerStatefulWidget {
  const TodoDetailPage({super.key, this.item, this.defaultDueDate, this.prefill});

  /// 编辑对象；为 null 表示新增。
  final TodoItem? item;

  /// 新增时的默认期限（来自主页面选中的日期）。
  final DateTime? defaultDueDate;

  /// 引用预填来源（如待办历史引用）。
  ///
  /// 仅用于「新增」场景（[item] 为 null）：预填标题、详情、附件、优先级、
  /// 分类与提醒设置，但不保留期限与循环规则。
  final TodoItem? prefill;

  @override
  ConsumerState<TodoDetailPage> createState() => _TodoDetailPageState();
}

class _TodoDetailPageState extends ConsumerState<TodoDetailPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _detailsController;

  late List<TodoImageAttachment> _images;
  late TodoPriority _priority;
  String? _categoryId;
  late bool _isRecurring;
  late List<RecurrenceRule> _recurrenceRules;
  DateTime? _dueDate;
  int? _remindMinutes;
  bool _remindEnabled = true;
  int _executionTimeMinutes = 540; // 09:00
  bool _remindAtExecution = true;
  bool _remindEarly = true;

  String? _titleError;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final prefill = widget.prefill;
    _titleController = TextEditingController(
      text: item?.title ?? prefill?.title ?? '',
    );
    _detailsController = TextEditingController(
      text: item?.details ?? prefill?.details ?? '',
    );
    _images = List.of(item?.images ?? prefill?.images ?? const []);
    _priority = item?.priority ?? prefill?.priority ?? TodoPriority.medium;
    _categoryId = item?.categoryId ?? prefill?.categoryId;
    // 引用预填不保留循环规则与期限。
    _recurrenceRules = List.of(item?.recurrenceRules ?? const []);
    _isRecurring = item?.isRecurring ?? false;
    _dueDate = item?.dueDate ??
        (_isRecurring ? null : widget.defaultDueDate?.toLocal());
    _remindMinutes = item?.remindMinutes ?? prefill?.remindMinutes;
    _remindEnabled = item?.remindEnabled ?? prefill?.remindEnabled ?? true;
    _executionTimeMinutes =
        item?.executionTimeMinutes ?? prefill?.executionTimeMinutes ?? 540;
    _remindAtExecution =
        item?.remindAtExecution ?? prefill?.remindAtExecution ?? true;
    _remindEarly = item?.remindEarly ?? prefill?.remindEarly ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? widget.defaultDueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickExecutionTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _executionTimeMinutes ~/ 60,
        minute: _executionTimeMinutes % 60,
      ),
    );
    if (picked != null) {
      setState(
        () => _executionTimeMinutes = picked.hour * 60 + picked.minute,
      );
    }
  }

  /// 通过底座文件选择能力挑选图片并转存为 base64 附件。
  Future<void> _addImage() async {
    final picked = await ref.read(filePickerProvider).pickImages();
    if (picked.isEmpty) return;
    final now = DateTime.now();
    final additions = <TodoImageAttachment>[];
    for (var i = 0; i < picked.length; i++) {
      final bytes = await picked[i].readContent();
      if (bytes.isEmpty) continue;
      additions.add(
        TodoImageAttachment(
          id: 'img_${now.microsecondsSinceEpoch}_$i',
          dataBase64: base64Encode(bytes),
          createdAt: now,
        ),
      );
    }
    if (additions.isEmpty) return;
    setState(() => _images = [..._images, ...additions]);
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = '请输入待办名称');
      return;
    }

    final now = DateTime.now();
    final existing = widget.item;
    final item = TodoItem(
      id: existing?.id ?? 'todo_${now.microsecondsSinceEpoch}',
      title: title,
      details: _detailsController.text.trim().isEmpty
          ? null
          : _detailsController.text.trim(),
      images: _images,
      categoryId: _categoryId,
      priority: _priority,
      dueDate: _isRecurring ? null : _dueDate,
      recurrenceRules: _isRecurring ? _recurrenceRules : const [],
      remindMinutes: _remindMinutes,
      remindEnabled: _remindEnabled,
      executionTimeMinutes: _executionTimeMinutes,
      remindAtExecution: _remindAtExecution,
      remindEarly: _remindEarly,
      isCompleted: existing?.isCompleted ?? false,
      completedAt: existing?.completedAt,
      isArchived: existing?.isArchived ?? false,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final controller = ref.read(todoListProvider);
    if (existing == null) {
      controller.add(item);
    } else {
      controller.update(item);
    }
    Navigator.of(context).pop();
  }

  /// 关闭待办确认（仅编辑已有事项时显示）。
  ///
  /// 循环类型：关闭整个循环（模板 + 实例）归入历史；
  /// 一次性：完成并归档该事项。
  Future<void> _confirmClose() async {
    final item = widget.item!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('关闭确认'),
        content: Text(
          item.isRecurring
              ? '确认关闭循环待办"${item.title}"吗？\n将结束整个循环，连同所有实例一并销项归入历史。'
              : '确认关闭待办"${item.title}"吗？\n关闭后将销项归入历史。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final controller = ref.read(todoListProvider);
    if (item.isRecurring) {
      await controller.closeRecurring(item.id);
    } else {
      await controller.toggleComplete(item.id);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final config = ref.watch(todoConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? '新增待办' : '编辑待办'),
        actions: [
          AdaptiveButton(
            variant: AdaptiveButtonVariant.text,
            label: '保存',
            onPressed: _save,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '名称 *',
              hintText: '待办事项名称',
              errorText: _titleError,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _detailsController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '详情',
              hintText: '补充说明（可选）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TodoImageAttachmentsEditor(
            images: _images,
            onChanged: (images) => setState(() => _images = images),
            onAdd: _addImage,
          ),
          const Divider(height: 32),
          Text('优先级', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          TodoPrioritySelector(
            value: _priority,
            onChanged: (p) => setState(() => _priority = p),
          ),
          const Divider(height: 32),
          Text('分类', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownMenu<String?>(
            width: 260,
            initialSelection: _categoryId,
            label: const Text('选择分类（可选）'),
            dropdownMenuEntries: [
              const DropdownMenuEntry<String?>(
                value: null,
                label: '无分类',
              ),
              for (final c in config.config.categories)
                DropdownMenuEntry<String?>(
                  value: c.id,
                  label: c.name,
                  leadingIcon: _CategoryColorDot(colorValue: c.colorValue),
                ),
            ],
            onSelected: (v) => setState(() => _categoryId = v),
          ),
          const Divider(height: 32),
          Text('循环类型', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<bool>(value: false, label: Text('一次性')),
              ButtonSegment<bool>(value: true, label: Text('循环')),
            ],
            selected: {_isRecurring},
            onSelectionChanged: (s) => setState(() => _isRecurring = s.first),
          ),
          const SizedBox(height: 8),
          if (_isRecurring)
            RecurrenceRuleEditor(
              rules: _recurrenceRules,
              onChanged: (rules) => setState(() => _recurrenceRules = rules),
            )
          else
            _DueDateField(
              dueDate: _dueDate,
              onTap: _pickDueDate,
            ),
          const Divider(height: 32),
          Text('提醒设置', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          _ReminderToggle(
            key: const ValueKey('item_remind_switch'),
            title: '提醒开关',
            subtitle: _remindEnabled ? '开启后按下方设置提醒' : '已关闭，本条待办不提醒',
            value: _remindEnabled,
            onChanged: (v) => setState(() => _remindEnabled = v),
          ),
          if (_remindEnabled) ...[
            const Divider(height: 1),
            // 执行时刻
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Expanded(child: Text('执行时刻')),
                  Text(
                    _fmtTimeOfDay(_executionTimeMinutes),
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(width: 4),
                  AdaptiveIconButton(
                    icon: const Icon(Icons.access_time),
                    tooltip: '选择执行时刻',
                    onPressed: _pickExecutionTime,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _ReminderToggle(
              key: const ValueKey('remind_at_execution_switch'),
              title: '执行时刻提醒',
              subtitle: '在命中日的执行时刻推送一次提醒',
              value: _remindAtExecution,
              onChanged: (v) => setState(() => _remindAtExecution = v),
            ),
            const Divider(height: 1),
            _ReminderToggle(
              key: const ValueKey('remind_early_switch'),
              title: '提前提醒',
              subtitle: '在执行时刻前 N 分钟推送一次提醒',
              value: _remindEarly,
              onChanged: (v) => setState(() => _remindEarly = v),
            ),
            if (_remindEarly) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(child: Text('提前分钟数')),
                    DropdownMenu<int?>(
                      width: 200,
                      initialSelection: _remindMinutes,
                      label: const Text('提前分钟数'),
                      dropdownMenuEntries: [
                        DropdownMenuEntry<int?>(
                          value: null,
                          label: '默认（${config.config.defaultRemindMinutes} 分钟）',
                        ),
                        for (final m in [5, 10, 15, 30, 60])
                          DropdownMenuEntry<int?>(value: m, label: '$m 分钟'),
                      ],
                      onSelected: (v) => setState(() => _remindMinutes = v),
                    ),
                  ],
                ),
              ),
            ],
          ],
          // 关闭待办（销项）：仅编辑已有事项时提供，新增时不提供。
          if (widget.item != null) ...[
            const Divider(height: 32),
            Text('关闭待办', style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              widget.item!.isRecurring
                  ? '关闭循环待办将结束整个循环，连同所有实例一并销项归入历史。'
                  : '关闭后该待办将销项归入历史。',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            AdaptiveButton(
              variant: AdaptiveButtonVariant.outlined,
              icon: Icons.flag_outlined,
              label: widget.item!.isRecurring ? '关闭循环待办' : '关闭此待办',
              onPressed: _confirmClose,
            ),
          ],
        ],
      ),
    );
  }
}

/// 一次性事项的期限选择字段。
class _DueDateField extends StatelessWidget {
  const _DueDateField({required this.dueDate, required this.onTap});

  final DateTime? dueDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text('期限', style: textTheme.titleSmall),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: onTap,
          child: Text(
            dueDate == null ? '选择日期（可选）' : _fmt(dueDate!),
            style: textTheme.bodyLarge?.copyWith(
              color: dueDate == null ? colorScheme.onSurfaceVariant : null,
            ),
          ),
        ),
      ],
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// 分类颜色圆点（配合 DropdownMenuEntry leadingIcon）。
class _CategoryColorDot extends StatelessWidget {
  const _CategoryColorDot({required this.colorValue});

  final int colorValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Color(colorValue),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// 提醒设置开关行（标题 + 副标题 + Md3Switch）。
class _ReminderToggle extends StatelessWidget {
  const _ReminderToggle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodyLarge),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Md3Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// 自 00:00 起分钟数 → "HH:mm"。
String _fmtTimeOfDay(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}