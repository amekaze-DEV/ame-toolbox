import 'package:dio/dio.dart';

/// 汇率 API 响应。
class ExchangeRateResponse {
  final String baseCurrency;
  final Map<String, double> rates;
  final DateTime? lastUpdated;
  final String sourceUrl;

  const ExchangeRateResponse({
    required this.baseCurrency,
    required this.rates,
    this.lastUpdated,
    required this.sourceUrl,
  });
}

/// 汇率 HTTP 客户端。
///
/// 使用 [Dio] 请求公开或自定义汇率源，支持 `{base}` 占位符替换、
/// 超时与错误处理。
class ExchangeRateClient {
  final Dio _dio;

  ExchangeRateClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  /// 请求以 [baseCurrency] 为基准的汇率表。
  ///
  /// [apiUrlTemplate] 必须包含 `{base}` 占位符，例如：
  /// `https://open.er-api.com/v6/latest/{base}`。
  Future<ExchangeRateResponse> fetchRates(
    String baseCurrency,
    String apiUrlTemplate,
  ) async {
    final sourceUrl = apiUrlTemplate.replaceAll('{base}', baseCurrency);

    final response = await _dio.get<Map<String, dynamic>>(sourceUrl);
    final data = response.data;

    if (data == null) {
      throw FormatException('汇率接口返回为空：$sourceUrl');
    }

    final ratesJson = data['rates'];
    if (ratesJson is! Map<String, dynamic>) {
      throw FormatException('汇率接口未包含 rates 字段：$sourceUrl');
    }

    final rates = <String, double>{};
    for (final entry in ratesJson.entries) {
      final value = entry.value;
      if (value is num) {
        rates[entry.key] = value.toDouble();
      }
    }

    if (rates.isEmpty) {
      throw FormatException('汇率接口 rates 为空：$sourceUrl');
    }

    DateTime? lastUpdated;
    final lastUpdateRaw = data['time_last_update_utc'];
    if (lastUpdateRaw is String) {
      lastUpdated = DateTime.tryParse(lastUpdateRaw);
    }

    return ExchangeRateResponse(
      baseCurrency: baseCurrency,
      rates: rates,
      lastUpdated: lastUpdated,
      sourceUrl: sourceUrl,
    );
  }
}
