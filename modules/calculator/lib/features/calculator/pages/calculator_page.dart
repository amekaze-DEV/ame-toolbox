import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ametoolbox/core/layout/responsive_builder.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../calculator_module.dart';
import '../models/calculator_config.dart';
import '../models/calculator_type.dart';
import '../providers/calculator_config_provider.dart';
import '../widgets/calculator_history_panel.dart';
import 'exchange_rate_page.dart';
import 'geometry_page.dart';
import 'history_page.dart';
import 'radix_converter_page.dart';
import 'scientific_calculator_page.dart';
import 'standard_cubic_mass_page.dart';
import 'unit_converter_page.dart';

/// 多功能计算器模块主页。
///
/// 负责顶部计算器类型切换、科学计数法开关、历史入口，
/// 并根据当前类型渲染对应的子计算器页面。
///
/// 竖屏为单列布局，横屏为双列布局并在侧边固定显示历史面板，
/// 面板左右位置由 [CalculatorConfig.historyPanelOnLeft] 控制。
class CalculatorPage extends ConsumerWidget {
  final CalculatorModule? module;

  const CalculatorPage({super.key, this.module});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveBuilder(
      portraitBuilder: (context) => _buildPortrait(context, ref),
      landscapeBuilder: (context) => _buildLandscape(context, ref),
    );
  }

  Widget _buildPortrait(BuildContext context, WidgetRef ref) {
    final configController = ref.watch(calculatorConfigProvider);
    final config = configController.config;
    final currentType = config.currentType;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: _buildTopControls(context, ref, currentType, config),
                ),
                AdaptiveIconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () => _openHistory(context),
                  tooltip: '计算历史',
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildCalculatorBody(context, ref, currentType),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscape(BuildContext context, WidgetRef ref) {
    final configController = ref.watch(calculatorConfigProvider);
    final config = configController.config;
    final currentType = config.currentType;

    final calculatorBody = Column(
      children: [
        _buildTopControls(context, ref, currentType, config),
        Expanded(
          child: _buildCalculatorBody(context, ref, currentType),
        ),
      ],
    );

    final historyPanel = CalculatorHistoryPanel(
      onBackfillExpression: () {},
    );

    return Scaffold(
      body: Row(
        children: [
          if (config.historyPanelOnLeft)
            Expanded(
              child: historyPanel,
            ),
          Expanded(child: calculatorBody),
          if (!config.historyPanelOnLeft)
            Expanded(
              child: historyPanel,
            ),
        ],
      ),
    );
  }

  Widget _buildTopControls(
    BuildContext context,
    WidgetRef ref,
    CalculatorType currentType,
    CalculatorConfig config,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypeDropdown(context, ref, currentType),
                if (currentType == CalculatorType.scientific) ...[
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '科学计数法',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Switch(
                        value: config.scientificNotation,
                        onChanged: (value) {
                          ref.read(calculatorConfigProvider).setScientificNotation(value);
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(
    BuildContext context,
    WidgetRef ref,
    CalculatorType currentType,
  ) {
    // 仅在横屏或需要紧凑显示时使用图标按钮；当前版本统一使用下拉。
    return const SizedBox.shrink();
  }

  Widget _buildTypeDropdown(
    BuildContext context,
    WidgetRef ref,
    CalculatorType currentType,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: DropdownMenu<CalculatorType>(
        width: 140,
        initialSelection: currentType,
        requestFocusOnTap: false,
        expandedInsets: EdgeInsets.zero,
        label: const Text('计算器'),
        dropdownMenuEntries: CalculatorType.values.map((type) {
          return DropdownMenuEntry(
            value: type,
            label: type.displayName,
          );
        }).toList(),
        onSelected: (value) {
          if (value != null) {
            ref.read(calculatorConfigProvider).setCurrentType(value);
          }
        },
      ),
    );
  }

  Widget _buildCalculatorBody(
    BuildContext context,
    WidgetRef ref,
    CalculatorType currentType,
  ) {
    switch (currentType) {
      case CalculatorType.scientific:
        return ScientificCalculatorPage(
          onHistoryPressed: () => _openHistory(context),
        );
      case CalculatorType.standardCubicToMass:
        return const StandardCubicMassPage();
      case CalculatorType.unitConverter:
        return const UnitConverterPage();
      case CalculatorType.geometry:
        return const GeometryPage();
      case CalculatorType.radix:
        return const RadixConverterPage();
      case CalculatorType.exchangeRate:
        return const ExchangeRatePage();
    }
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HistoryPage()),
    );
  }
}
