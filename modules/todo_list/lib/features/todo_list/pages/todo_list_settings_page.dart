import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/layout/responsive_builder.dart';
import 'package:ametoolbox/shared/widgets/md3_switch.dart';

import '../providers/todo_config_provider.dart';
import '../widgets/todo_category_manager.dart';
import 'todo_summary_page.dart';

/// 待办设置页（P7）。
///
/// 分区：分类管理、列表显示、提醒设置。
/// 使用底座 [ResponsiveBuilder] 适配横竖屏。
class TodoListSettingsPage extends ConsumerWidget {
  const TodoListSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveBuilder(
      portraitBuilder: (_) => _buildBody(context, ref, twoColumns: false),
      landscapeBuilder: (_) => _buildBody(context, ref, twoColumns: true),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, {required bool twoColumns}) {
    final config = ref.watch(todoConfigProvider);

    final remindSection = _Section(
      title: '全局提醒设置',
      children: [
        _SwitchRow(
          key: const ValueKey('remind_enabled_switch'),
          title: '到期提醒',
          subtitle: '开启后按期限提前推送系统通知',
          value: config.config.remindEnabled,
          onChanged: (v) => ref.read(todoConfigProvider).setRemindEnabled(v),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Expanded(child: Text('默认提前分钟数')),
              DropdownMenu<int>(
                key: ValueKey(
                  'remind_minutes_${config.config.defaultRemindMinutes}',
                ),
                width: 200,
                initialSelection: config.config.defaultRemindMinutes,
                dropdownMenuEntries:
                    _remindMinutesEntries(config.config.defaultRemindMinutes),
                onSelected: (v) async {
                  if (v == null) return;
                  if (v == _customRemindMinutesValue) {
                    final value = await _promptCustomMinutes(
                      context,
                      config.config.defaultRemindMinutes,
                    );
                    if (value != null) {
                      ref
                          .read(todoConfigProvider)
                          .setDefaultRemindMinutes(value);
                    }
                  } else {
                    ref.read(todoConfigProvider).setDefaultRemindMinutes(v);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );

    final displaySection = _Section(
      title: '列表显示',
      children: [
        _SwitchRow(
          title: '日常事项置顶',
          subtitle: '开启后日常优先级事项排在最前',
          value: config.config.dailyTop,
          onChanged: (v) => ref.read(todoConfigProvider).setDailyTop(v),
        ),
      ],
    );

    final categorySection = _Section(
      title: null,
      children: [
        const TodoCategoryManager(),
      ],
    );

    final querySection = _Section(
      title: '查询',
      children: [
        ListTile(
          leading: const Icon(Icons.fact_check_outlined),
          title: const Text('待办汇总'),
          subtitle: const Text('在运转的待办与待办历史'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TodoSummaryPage(),
            ),
          ),
        ),
      ],
    );

    final sections = <Widget>[
      querySection,
      categorySection,
      displaySection,
      remindSection,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: twoColumns
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: categorySection),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          querySection,
                          displaySection,
                          remindSection,
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: sections,
            ),
    );
  }

  /// 「自定义…」下拉条目的占位值（不会写入配置）。
  static const int _customRemindMinutesValue = -1;

  /// 预设的默认提前分钟数选项。
  static const List<int> _presetRemindMinutes = [5, 10, 15, 30, 60];

  /// 构建「默认提前分钟数」下拉条目。
  ///
  /// 预设项 + （若当前值不在预设中）当前自定义值项 + 「自定义…」。
  static List<DropdownMenuEntry<int>> _remindMinutesEntries(int current) {
    return [
      for (final m in _presetRemindMinutes)
        DropdownMenuEntry(value: m, label: '$m 分钟'),
      if (!_presetRemindMinutes.contains(current))
        DropdownMenuEntry(value: current, label: '自定义 $current 分钟'),
      const DropdownMenuEntry(
        value: _customRemindMinutesValue,
        label: '自定义…',
      ),
    ];
  }

  /// 弹出「自定义提前分钟数」输入对话框，返回正整数分钟数。
  Future<int?> _promptCustomMinutes(BuildContext context, int current) async {
    final controller = TextEditingController(text: '$current');
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('自定义提前分钟数'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: '分钟数',
            helperText: '请输入正整数分钟数',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value <= 0) return;
              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 设置分组卡片。
class _Section extends StatelessWidget {
  const _Section({this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(title!, style: textTheme.titleSmall),
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// 开关设置行。
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
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