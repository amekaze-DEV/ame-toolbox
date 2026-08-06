/// 汇率缓存数据。
///
/// 保存最近一次成功获取的汇率表及来源信息，用于离线回退。
class ExchangeRateCache {
  /// 基准货币代码，如 `USD`。
  final String baseCurrency;

  /// 以基准货币为底的汇率表，`{货币代码: 汇率}`。
  final Map<String, double> rates;

  /// 缓存最后更新时间（UTC）。
  final DateTime lastUpdated;

  /// 实际请求地址，便于调试与区分自定义源。
  final String sourceUrl;

  const ExchangeRateCache({
    required this.baseCurrency,
    required this.rates,
    required this.lastUpdated,
    required this.sourceUrl,
  });

  /// 创建一份除指定字段外均相同的副本。
  ExchangeRateCache copyWith({
    String? baseCurrency,
    Map<String, double>? rates,
    DateTime? lastUpdated,
    String? sourceUrl,
  }) {
    return ExchangeRateCache(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      rates: rates ?? Map.unmodifiable(this.rates),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      sourceUrl: sourceUrl ?? this.sourceUrl,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() {
    return {
      'baseCurrency': baseCurrency,
      'rates': rates,
      'lastUpdated': lastUpdated.toIso8601String(),
      'sourceUrl': sourceUrl,
    };
  }

  /// 从 JSON 反序列化。
  factory ExchangeRateCache.fromJson(Map<String, dynamic> json) {
    final ratesJson = json['rates'] as Map<String, dynamic>? ?? {};
    final rates = <String, double>{};
    for (final entry in ratesJson.entries) {
      final value = entry.value;
      if (value is num) {
        rates[entry.key] = value.toDouble();
      }
    }

    return ExchangeRateCache(
      baseCurrency: json['baseCurrency'] as String? ?? 'USD',
      rates: rates,
      lastUpdated: DateTime.tryParse(json['lastUpdated'] as String? ?? '') ??
          DateTime.utc(1970),
      sourceUrl: json['sourceUrl'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'ExchangeRateCache(baseCurrency: $baseCurrency, '
        'ratesCount: ${rates.length}, lastUpdated: $lastUpdated, '
        'sourceUrl: $sourceUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExchangeRateCache &&
        other.baseCurrency == baseCurrency &&
        _mapEquals(other.rates, rates) &&
        other.lastUpdated == lastUpdated &&
        other.sourceUrl == sourceUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      baseCurrency,
      Object.hashAll(rates.entries),
      lastUpdated,
      sourceUrl,
    );
  }
}

/// 比较两个 [Map] 的内容是否相等。
bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) return false;
  }
  return true;
}
