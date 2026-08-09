import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../providers/calculator_config_provider.dart';

/// 多功能计算器模块专属设置页。
///
/// 支持小数精度、科学计数法、横屏历史面板位置、键盘显示、
/// 首页卡片开关与顺序、汇率源地址、进制 NOT 位宽以及清除历史。
class CalculatorSettingsPage extends ConsumerWidget {
  const CalculatorSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configController = ref.watch(calculatorConfigProvider);
    final config = configController.config;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('计算器设置'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: '显示与精度',
            children: [
              _DecimalPrecisionTile(
                value: config.decimalPrecision,
                onChanged: (value) => configController.setDecimalPrecision(value),
              ),
              SwitchListTile(
                title: const Text('科学计数法'),
                subtitle: const Text('结果以科学计数法显示'),
                value: config.scientificNotation,
                onChanged: (value) => configController.setScientificNotation(value),
              ),
              SwitchListTile(
                title: const Text('显示完整数字键盘'),
                subtitle: const Text('关闭后科学计算器仅保留算符与函数'),
                value: config.showFullKeyboard,
                onChanged: (value) => configController.setShowFullKeyboard(value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: '布局',
            children: [
              SwitchListTile(
                title: const Text('横屏历史面板在左侧'),
                subtitle: const Text('默认在右侧'),
                value: config.historyPanelOnLeft,
                onChanged: (value) => configController.setHistoryPanelOnLeft(value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: '首页仪表盘卡片',
            children: [
              SwitchListTile(
                title: const Text('首页快速计算'),
                subtitle: const Text('在首页显示快速计算卡片（含最近计算）'),
                value: config.dashboardQuickCalc,
                onChanged: (value) => configController.setDashboardQuickCalc(value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: '汇率与进制',
            children: [
              _ExchangeRateUrlTile(
                url: config.exchangeRateApiUrl,
                onChanged: (value) => configController.setExchangeRateApiUrl(value),
              ),
              _RadixBitWidthTile(
                value: config.radixNotBitWidth,
                onChanged: (value) => configController.setRadixNotBitWidth(value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: '数据管理',
            children: [
              ListTile(
                title: const Text('清除计算历史'),
                subtitle: Text('当前共 ${config.history.length} 条记录'),
                trailing: AdaptiveButton(
                  variant: AdaptiveButtonVariant.text,
                  label: '清除',
                  onPressed: config.history.isEmpty
                      ? null
                      : () => _showClearConfirm(context, ref),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '模块 ID: calculator',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showClearConfirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除历史'),
        content: const Text('确定要清空所有计算历史吗？此操作不可恢复。'),
        actions: [
          AdaptiveButton(
            variant: AdaptiveButtonVariant.text,
            label: '取消',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AdaptiveButton(
            variant: AdaptiveButtonVariant.text,
            label: '清除',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(calculatorConfigProvider).clearHistory();
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DecimalPrecisionTile extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _DecimalPrecisionTile({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('小数精度'),
      subtitle: Text('$value 位'),
      trailing: SizedBox(
        width: 160,
        child: Slider(
          value: value.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          label: value.toString(),
          onChanged: (value) => onChanged(value.round()),
        ),
      ),
    );
  }
}

class _ExchangeRateUrlTile extends StatefulWidget {
  final String url;
  final ValueChanged<String> onChanged;

  const _ExchangeRateUrlTile({
    required this.url,
    required this.onChanged,
  });

  @override
  State<_ExchangeRateUrlTile> createState() => _ExchangeRateUrlTileState();
}

class _ExchangeRateUrlTileState extends State<_ExchangeRateUrlTile> {
  late final TextEditingController _controller;
  bool _hasBasePlaceholder = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.url);
    _hasBasePlaceholder = widget.url.contains('{base}');
  }

  @override
  void didUpdateWidget(covariant _ExchangeRateUrlTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller.text = widget.url;
      _hasBasePlaceholder = widget.url.contains('{base}');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: '汇率源地址',
              hintText: 'https://open.er-api.com/v6/latest/{base}',
              errorText: _hasBasePlaceholder ? null : '地址必须包含 {base} 占位符',
              suffixIcon: AdaptiveIconButton(
                icon: const Icon(Icons.check),
                tooltip: '保存',
                onPressed: _save,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _hasBasePlaceholder = value.contains('{base}');
              });
            },
          ),
          const SizedBox(height: 4),
          Text(
            '必须包含 {base} 占位符，用于替换基准货币。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final url = _controller.text.trim();
    if (url.contains('{base}')) {
      widget.onChanged(url);
    }
  }
}

class _RadixBitWidthTile extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _RadixBitWidthTile({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('进制 NOT 位宽'),
      subtitle: const Text('按指定位宽对负数取反'),
      trailing: DropdownMenu<int>(
        initialSelection: value,
        dropdownMenuEntries: const [
          DropdownMenuEntry(value: 8, label: '8 位'),
          DropdownMenuEntry(value: 16, label: '16 位'),
          DropdownMenuEntry(value: 32, label: '32 位'),
          DropdownMenuEntry(value: 64, label: '64 位'),
        ],
        onSelected: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}
