import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_module/features/calculator/models/exchange_rate_cache.dart';
import 'package:calculator_module/features/calculator/services/exchange_rate_client.dart';
import 'package:calculator_module/features/calculator/services/exchange_rate_service.dart';

class _FakeClient implements ExchangeRateClient {
  final ExchangeRateResponse? response;
  final Exception? exception;

  String? lastBaseCurrency;
  String? lastApiUrlTemplate;

  _FakeClient({this.response, this.exception});

  @override
  Future<ExchangeRateResponse> fetchRates(
    String baseCurrency,
    String apiUrlTemplate,
  ) async {
    lastBaseCurrency = baseCurrency;
    lastApiUrlTemplate = apiUrlTemplate;
    if (exception != null) throw exception!;
    if (response == null) throw Exception('未配置响应');
    return response!;
  }
}

void main() {
  group('ExchangeRateService', () {
    late ExchangeRateService service;

    setUp(() {
      service = ExchangeRateService();
    });

    group('currencyNames', () {
      test('返回已知货币的中文名', () {
        expect(ExchangeRateService.getCurrencyDisplayName('CNY'), '人民币');
        expect(ExchangeRateService.getCurrencyDisplayName('USD'), '美元');
        expect(ExchangeRateService.getCurrencyDisplayName('EUR'), '欧元');
      });

      test('未知货币返回代码本身', () {
        expect(ExchangeRateService.getCurrencyDisplayName('XXX'), 'XXX');
      });

      test('默认货币列表均有中文名', () {
        for (final code in ExchangeRateService.defaultCurrencies) {
          expect(ExchangeRateService.currencyNames, containsPair(code, isNotEmpty));
        }
      });
    });

    group('getCurrencies', () {
      test('无缓存时返回默认 12 种货币', () {
        final currencies = service.getCurrencies(null);
        expect(currencies, hasLength(12));
        expect(currencies, contains('CNY'));
        expect(currencies, contains('USD'));
        expect(currencies, contains('EUR'));
      });

      test('有缓存时返回缓存中的货币并排序', () {
        final cache = ExchangeRateCache(
          baseCurrency: 'USD',
          rates: {'CNY': 7.2, 'EUR': 0.9},
          lastUpdated: DateTime.utc(2026, 1, 1),
          sourceUrl: 'https://example.com/USD',
        );
        final currencies = service.getCurrencies(cache);
        expect(currencies, equals(['CNY', 'EUR', 'USD']));
      });
    });

    group('convert', () {
      final cache = ExchangeRateCache(
        baseCurrency: 'USD',
        rates: {
          'CNY': 7.2,
          'EUR': 0.9,
          'JPY': 150.0,
        },
        lastUpdated: DateTime.utc(2026, 1, 1),
        sourceUrl: 'https://example.com/USD',
      );

      test('相同货币返回原值', () {
        final result = service.convert(100, 'USD', 'USD', cache);
        expect(result, 100);
      });

      test('USD 转 CNY 正确', () {
        final result = service.convert(100, 'USD', 'CNY', cache);
        expect(result, closeTo(720, 1e-9));
      });

      test('CNY 转 EUR 正确', () {
        final result = service.convert(720, 'CNY', 'EUR', cache);
        expect(result, closeTo(90, 1e-9));
      });

      test('缓存中不存在的货币返回 null', () {
        final result = service.convert(100, 'USD', 'XXX', cache);
        expect(result, isNull);
      });
    });

    group('refresh', () {
      test('网络成功时返回 success 与新缓存', () async {
        final client = _FakeClient(
          response: ExchangeRateResponse(
            baseCurrency: 'USD',
            rates: {'CNY': 7.2},
            lastUpdated: DateTime.utc(2026, 1, 1),
            sourceUrl: 'https://example.com/USD',
          ),
        );
        final serviceWithClient = ExchangeRateService(client: client);
        final result = await serviceWithClient.refresh('USD', '{base}', null);

        expect(result.status, ExchangeRateStatus.success);
        expect(result.cache, isNotNull);
        expect(result.cache!.baseCurrency, 'USD');
        expect(result.cache!.rates['CNY'], 7.2);
      });

      test('服务将 URL 模板原样传递给客户端', () async {
        final client = _FakeClient(
          response: ExchangeRateResponse(
            baseCurrency: 'USD',
            rates: {'CNY': 7.2},
            lastUpdated: DateTime.utc(2026, 1, 1),
            sourceUrl: 'https://example.com/USD',
          ),
        );
        final serviceWithClient = ExchangeRateService(client: client);
        await serviceWithClient.refresh('USD', 'https://api.example.com/{base}', null);

        expect(client.lastApiUrlTemplate, 'https://api.example.com/{base}');
      });

      test('网络失败且有缓存时返回 offline', () async {
        final client = _FakeClient(exception: Exception('network error'));
        final serviceWithClient = ExchangeRateService(client: client);
        final cache = ExchangeRateCache(
          baseCurrency: 'USD',
          rates: {'CNY': 7.2},
          lastUpdated: DateTime.utc(2026, 1, 1, 12, 30),
          sourceUrl: 'https://example.com/USD',
        );

        final result = await serviceWithClient.refresh('USD', '{base}', cache);

        expect(result.status, ExchangeRateStatus.offline);
        expect(result.cache, equals(cache));
        expect(result.message, contains('离线缓存'));
        expect(result.message, contains('2026-01-01 12:30'));
      });

      test('网络失败且无缓存时返回 error', () async {
        final client = _FakeClient(exception: Exception('network error'));
        final serviceWithClient = ExchangeRateService(client: client);

        final result = await serviceWithClient.refresh('USD', '{base}', null);

        expect(result.status, ExchangeRateStatus.error);
        expect(result.cache, isNull);
        expect(result.message, contains('暂无汇率数据'));
      });
    });
  });
}
