import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/calculator_config_provider.dart';
import '../providers/scientific_calculator_provider.dart';
import '../widgets/scientific_keypad.dart';

/// 科学计算器页面。
///
/// 布局：上方为可向上滚动的历史记录卷轴，下方为当前输入/结果与键盘。
class ScientificCalculatorPage extends ConsumerStatefulWidget {
  final VoidCallback? onHistoryPressed;

  const ScientificCalculatorPage({super.key, this.onHistoryPressed});

  @override
  ConsumerState<ScientificCalculatorPage> createState() =>
      _ScientificCalculatorPageState();
}

class _ScientificCalculatorPageState
    extends ConsumerState<ScientificCalculatorPage> {
  bool _secondFunction = false;
  final ScrollController _historyScrollController = ScrollController();

  @override
  void dispose() {
    _historyScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(scientificCalculatorProvider);
    final config = ref.watch(calculatorConfigProvider).config;
    final colorScheme = Theme.of(context).colorScheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollHistoryToBottom();
    });

    return Column(
      children: [
        // 上方：历史记录卷轴
        Expanded(
          child: _buildHistoryScroll(context, controller.history),
        ),
        // 下方：当前输入 / 结果
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 当前表达式或结果
              Text(
                controller.expression.isNotEmpty
                    ? controller.expression
                    : controller.result.display,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: controller.result.isError &&
                              controller.expression.isEmpty
                          ? colorScheme.error
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 4),
              // 错误详情
              if (controller.result.isError &&
                  controller.result.errorMessage != null)
                Text(
                  controller.result.errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                  textAlign: TextAlign.right,
                ),
            ],
          ),
        ),
        // 键盘
        ScientificKeypad(
          showFullKeyboard: config.showFullKeyboard,
          degrees: controller.degrees,
          secondFunction: _secondFunction,
          onKeyPressed: (value) => _handleKeyPress(controller, value),
          onToggleSecondFunction: () {
            setState(() {
              _secondFunction = !_secondFunction;
            });
          },
          onToggleAngleMode: controller.toggleAngleMode,
        ),
      ],
    );
  }

  Widget _buildHistoryScroll(BuildContext context, List<dynamic> history) {
    final colorScheme = Theme.of(context).colorScheme;

    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      controller: _historyScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final record = history[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            onTap: () {
              ref.read(scientificCalculatorProvider).useHistory(record);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '${record.expression} = ${record.result}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
          ),
        );
      },
    );
  }

  void _scrollHistoryToBottom() {
    if (!_historyScrollController.hasClients) return;
    _historyScrollController.animateTo(
      _historyScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _handleKeyPress(dynamic controller, String value) {
    switch (value) {
      case 'C':
        controller.clear();
        break;
      case 'backspace':
        controller.backspace();
        break;
      case '=':
        controller.calculate();
        break;
      default:
        controller.append(value);
    }
  }
}
