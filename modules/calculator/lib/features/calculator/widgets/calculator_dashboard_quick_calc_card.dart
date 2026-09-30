import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ametoolbox/shared/utils/app_text_styles.dart';
import 'package:intl/intl.dart';

import '../models/calculation_history.dart';
import '../models/calculator_type.dart';
import '../providers/calculator_config_provider.dart';
import '../providers/scientific_calculator_provider.dart';
import '../services/history_backfill_service.dart';

/// 多功能计算器的首页入口卡片（快速计算 + 最近计算历史）。
///
/// 作为模块入口卡片替换首页通用的模块摘要卡片，可随首页模块列表拖动排序。
/// 上部提供极简算式输入框与软键盘（`+ - × ÷ ( ) C =`），实时显示计算结果；
/// 按下 `=` 计算成功后写入科学计算历史记录。
/// 下部展示最近 5 条计算历史，点击条目通过 [onOpenModule] 进入模块主页并回填。
///
/// 卡片使用 [MainAxisSize.min] 与可收缩的历史列表，高度随内容自适应。
class CalculatorDashboardQuickCalcCard extends ConsumerStatefulWidget {
  const CalculatorDashboardQuickCalcCard({
    super.key,
    required this.onOpenModule,
  });

  /// 进入多功能计算器模块主页的回调（切换底座导航，保留导航栏）。
  final VoidCallback onOpenModule;

  @override
  ConsumerState<CalculatorDashboardQuickCalcCard> createState() =>
      _CalculatorDashboardQuickCalcCardState();
}

class _CalculatorDashboardQuickCalcCardState
    extends ConsumerState<CalculatorDashboardQuickCalcCard> {
  final TextEditingController _controller = TextEditingController();
  String _result = '';

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      calculatorConfigProvider,
      (previous, next) {
        final prevConfig = previous?.config;
        final nextConfig = next.config;
        if (prevConfig?.scientificNotation != nextConfig.scientificNotation ||
            prevConfig?.decimalPrecision != nextConfig.decimalPrecision) {
          _onExpressionChanged(_controller.text);
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(calculatorConfigProvider).config;
    final history = config.history.take(5).toList();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  color: colorScheme.primary,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '多功能计算器',
                    style: AppTextStyles.cardTitle(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '输入算式',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              style: textTheme.bodyLarge,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _calculate(),
              onChanged: _onExpressionChanged,
            ),
            const SizedBox(height: 4),
            Text(
              _result.isEmpty ? ' ' : _result,
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            _OperatorBar(
              onOperator: _append,
              onClear: _clear,
              onCalculate: _calculate,
            ),
            const Divider(height: 16),
            Text(
              '最近计算',
              style: AppTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: 4),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '暂无计算记录',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 216),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final record = history[index];
                    return _HistoryTile(
                      record: record,
                      onTap: () => _backfillAndOpen(context, record),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onExpressionChanged(String expression) {
    final config = ref.read(calculatorConfigProvider).config;
    final service = ref.read(scientificCalculatorServiceProvider);
    final result = service.evaluate(
      expression,
      degrees: true,
      precision: config.decimalPrecision,
      scientificNotation: config.scientificNotation,
    );
    setState(() {
      _result = result.isError ? '' : result.display;
    });
  }

  void _append(String value) {
    final text = _controller.text;
    _controller.text = text + value;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _onExpressionChanged(_controller.text);
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _result = '';
    });
  }

  /// 计算并将成功结果写入科学计算历史记录。
  void _calculate() {
    final expression = _controller.text.trim();
    if (expression.isEmpty) return;

    final configController = ref.read(calculatorConfigProvider);
    final config = configController.config;
    final service = ref.read(scientificCalculatorServiceProvider);
    final result = service.evaluate(
      expression,
      degrees: true,
      precision: config.decimalPrecision,
      scientificNotation: config.scientificNotation,
    );

    if (!result.isError && result.value != null) {
      configController.addHistory(
        CalculationHistory(
          expression: expression,
          result: result.display,
          timestamp: DateTime.now().toUtc(),
          angleMode: 'DEG',
          calculatorType: CalculatorType.scientific,
        ),
      );
      _controller.clear();
    }
    setState(() {
      _result = result.isError ? '' : result.display;
    });
  }

  Future<void> _backfillAndOpen(
    BuildContext context,
    CalculationHistory record,
  ) async {
    await HistoryBackfillService.backfillExpression(ref, record);
    if (context.mounted) {
      widget.onOpenModule();
    }
  }
}

/// 精简软键盘：`+ - × ÷ ( ) C =`。
class _OperatorBar extends StatelessWidget {
  final ValueChanged<String> onOperator;
  final VoidCallback onClear;
  final VoidCallback onCalculate;

  const _OperatorBar({
    required this.onOperator,
    required this.onClear,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    const operators = ['+', '-', '×', '÷', '(', ')'];

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final op in operators)
          _OperatorButton(
            label: op,
            onPressed: () => onOperator(_mapOperator(op)),
          ),
        _OperatorButton(
          label: 'C',
          onPressed: onClear,
        ),
        _OperatorButton(
          label: '=',
          onPressed: onCalculate,
        ),
      ],
    );
  }

  String _mapOperator(String op) {
    return switch (op) {
      '×' => '*',
      '÷' => '/',
      _ => op,
    };
  }
}

/// 精简算符栏中的单个按钮。
///
/// [ActionChip] 的可见区域贴合标签内容宽度，不同字符（如 `+` 与 `(`）会导致
/// 按钮宽度不一致且居中显示；这里用固定宽度的标签容器统一所有按钮的可见尺寸。
class _OperatorButton extends StatelessWidget {
  const _OperatorButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  /// 标签统一宽度，保证每个按钮的可见尺寸完全一致。
  static const double _labelWidth = 16;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: SizedBox(
        width: _labelWidth,
        child: Text(
          label,
          textAlign: TextAlign.center,
        ),
      ),
      onPressed: onPressed,
    );
  }
}

/// 单条最近计算记录。
class _HistoryTile extends StatelessWidget {
  final CalculationHistory record;
  final VoidCallback onTap;

  const _HistoryTile({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeText = DateFormat('MM-dd HH:mm').format(
      record.timestamp.toLocal(),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              record.expression,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.result,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  timeText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}