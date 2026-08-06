import 'calculator_type.dart';
import 'calculation_history.dart';
import 'exchange_rate_cache.dart';

/// 多功能计算器模块级配置。
///
/// 包含当前计算器类型、显示设置、布局设置、首页卡片设置、汇率源设置
/// 以及科学计算器历史记录与汇率缓存。
class CalculatorConfig {
  /// 当前选中的计算器，默认 [CalculatorType.scientific]。
  final CalculatorType currentType;

  /// 小数精度，范围 0-10，默认 6。
  final int decimalPrecision;

  /// 是否以科学计数法显示结果，默认 false。
  final bool scientificNotation;

  /// 横屏下历史面板是否在左侧，默认 false（右侧）。
  final bool historyPanelOnLeft;

  /// 是否显示完整数字键盘，默认 true。
  final bool showFullKeyboard;

  /// 首页是否显示快速计算器卡片，默认 true。
  final bool dashboardQuickCalc;

  /// 首页是否显示最近历史卡片，默认 true。
  final bool dashboardHistory;

  /// 快速计算器卡片排序，默认 0。
  final int dashboardQuickCalcOrder;

  /// 历史卡片排序，默认 1。
  final int dashboardHistoryOrder;

  /// 自定义汇率源地址，必须包含 `{base}` 占位符。
  final String exchangeRateApiUrl;

  /// 进制 NOT 位宽，可选 8/16/32/64，默认 32。
  final int radixNotBitWidth;

  /// 科学计算器历史记录，最多 20 条。
  final List<CalculationHistory> history;

  /// 汇率缓存。
  final ExchangeRateCache? exchangeRates;

  const CalculatorConfig({
    this.currentType = CalculatorType.scientific,
    this.decimalPrecision = 6,
    this.scientificNotation = false,
    this.historyPanelOnLeft = false,
    this.showFullKeyboard = true,
    this.dashboardQuickCalc = true,
    this.dashboardHistory = true,
    this.dashboardQuickCalcOrder = 0,
    this.dashboardHistoryOrder = 1,
    this.exchangeRateApiUrl = 'https://open.er-api.com/v6/latest/{base}',
    this.radixNotBitWidth = 32,
    this.history = const [],
    this.exchangeRates,
  });

  /// 默认配置常量。
  static const CalculatorConfig defaults = CalculatorConfig();

  /// 创建一份除指定字段外均相同的副本。
  CalculatorConfig copyWith({
    CalculatorType? currentType,
    int? decimalPrecision,
    bool? scientificNotation,
    bool? historyPanelOnLeft,
    bool? showFullKeyboard,
    bool? dashboardQuickCalc,
    bool? dashboardHistory,
    int? dashboardQuickCalcOrder,
    int? dashboardHistoryOrder,
    String? exchangeRateApiUrl,
    int? radixNotBitWidth,
    List<CalculationHistory>? history,
    ExchangeRateCache? exchangeRates,
  }) {
    return CalculatorConfig(
      currentType: currentType ?? this.currentType,
      decimalPrecision: decimalPrecision ?? this.decimalPrecision,
      scientificNotation: scientificNotation ?? this.scientificNotation,
      historyPanelOnLeft: historyPanelOnLeft ?? this.historyPanelOnLeft,
      showFullKeyboard: showFullKeyboard ?? this.showFullKeyboard,
      dashboardQuickCalc: dashboardQuickCalc ?? this.dashboardQuickCalc,
      dashboardHistory: dashboardHistory ?? this.dashboardHistory,
      dashboardQuickCalcOrder:
          dashboardQuickCalcOrder ?? this.dashboardQuickCalcOrder,
      dashboardHistoryOrder:
          dashboardHistoryOrder ?? this.dashboardHistoryOrder,
      exchangeRateApiUrl: exchangeRateApiUrl ?? this.exchangeRateApiUrl,
      radixNotBitWidth: radixNotBitWidth ?? this.radixNotBitWidth,
      history: history ?? List.unmodifiable(this.history),
      exchangeRates: exchangeRates ?? this.exchangeRates,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() {
    return {
      'currentType': currentType.value,
      'decimalPrecision': decimalPrecision,
      'scientificNotation': scientificNotation,
      'historyPanelOnLeft': historyPanelOnLeft,
      'showFullKeyboard': showFullKeyboard,
      'dashboardQuickCalc': dashboardQuickCalc,
      'dashboardHistory': dashboardHistory,
      'dashboardQuickCalcOrder': dashboardQuickCalcOrder,
      'dashboardHistoryOrder': dashboardHistoryOrder,
      'exchangeRateApiUrl': exchangeRateApiUrl,
      'radixNotBitWidth': radixNotBitWidth,
      'history': history.map((e) => e.toJson()).toList(),
      'exchangeRates': exchangeRates?.toJson(),
    };
  }

  /// 从 JSON 反序列化。
  factory CalculatorConfig.fromJson(Map<String, dynamic> json) {
    final historyJson = json['history'] as List<dynamic>? ?? [];
    final history = historyJson
        .whereType<Map<String, dynamic>>()
        .map(CalculationHistory.fromJson)
        .toList();

    final exchangeRatesJson = json['exchangeRates'] as Map<String, dynamic>?;

    return CalculatorConfig(
      currentType: CalculatorTypeExtension.fromString(
          json['currentType'] as String?),
      decimalPrecision: json['decimalPrecision'] as int? ?? 6,
      scientificNotation: json['scientificNotation'] as bool? ?? false,
      historyPanelOnLeft: json['historyPanelOnLeft'] as bool? ?? false,
      showFullKeyboard: json['showFullKeyboard'] as bool? ?? true,
      dashboardQuickCalc: json['dashboardQuickCalc'] as bool? ?? true,
      dashboardHistory: json['dashboardHistory'] as bool? ?? true,
      dashboardQuickCalcOrder:
          json['dashboardQuickCalcOrder'] as int? ?? 0,
      dashboardHistoryOrder: json['dashboardHistoryOrder'] as int? ?? 1,
      exchangeRateApiUrl: json['exchangeRateApiUrl'] as String? ??
          'https://open.er-api.com/v6/latest/{base}',
      radixNotBitWidth: json['radixNotBitWidth'] as int? ?? 32,
      history: history,
      exchangeRates: exchangeRatesJson != null
          ? ExchangeRateCache.fromJson(exchangeRatesJson)
          : null,
    );
  }

  @override
  String toString() {
    return 'CalculatorConfig(currentType: ${currentType.value}, '
        'decimalPrecision: $decimalPrecision, '
        'scientificNotation: $scientificNotation, '
        'historyPanelOnLeft: $historyPanelOnLeft, '
        'showFullKeyboard: $showFullKeyboard, '
        'historyCount: ${history.length})';
  }


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalculatorConfig &&
        other.currentType == currentType &&
        other.decimalPrecision == decimalPrecision &&
        other.scientificNotation == scientificNotation &&
        other.historyPanelOnLeft == historyPanelOnLeft &&
        other.showFullKeyboard == showFullKeyboard &&
        other.dashboardQuickCalc == dashboardQuickCalc &&
        other.dashboardHistory == dashboardHistory &&
        other.dashboardQuickCalcOrder == dashboardQuickCalcOrder &&
        other.dashboardHistoryOrder == dashboardHistoryOrder &&
        other.exchangeRateApiUrl == exchangeRateApiUrl &&
        other.radixNotBitWidth == radixNotBitWidth &&
        _historyEquals(other.history, history) &&
        other.exchangeRates == exchangeRates;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentType,
      decimalPrecision,
      scientificNotation,
      historyPanelOnLeft,
      showFullKeyboard,
      dashboardQuickCalc,
      dashboardHistory,
      dashboardQuickCalcOrder,
      dashboardHistoryOrder,
      exchangeRateApiUrl,
      radixNotBitWidth,
      Object.hashAll(history),
      exchangeRates,
    );
  }
}

/// 比较两个 [CalculationHistory] 列表的内容是否相等。
bool _historyEquals(
  List<CalculationHistory> a,
  List<CalculationHistory> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
