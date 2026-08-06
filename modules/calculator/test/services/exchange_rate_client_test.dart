import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:calculator_module/features/calculator/services/exchange_rate_client.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  group('ExchangeRateClient', () {
    late _MockDio dio;
    late ExchangeRateClient client;

    setUp(() {
      dio = _MockDio();
      client = ExchangeRateClient(dio: dio);
    });

    test('将 {base} 替换为 USD 并请求', () async {
      when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: ''),
          data: {
            'rates': {'CNY': 7.2},
            'time_last_update_utc': '2026-01-01T00:00:00Z',
          },
          statusCode: 200,
        ),
      );

      final response = await client.fetchRates(
        'USD',
        'https://open.er-api.com/v6/latest/{base}',
      );

      verify(
        () => dio.get<Map<String, dynamic>>(
          'https://open.er-api.com/v6/latest/USD',
        ),
      ).called(1);
      expect(response.baseCurrency, 'USD');
      expect(response.rates['CNY'], 7.2);
      expect(response.sourceUrl, 'https://open.er-api.com/v6/latest/USD');
    });

    test('rates 为空时抛出 FormatException', () async {
      when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: ''),
          data: {'rates': <String, dynamic>{}},
          statusCode: 200,
        ),
      );

      expect(
        () => client.fetchRates('USD', '{base}'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('rates 为空'),
        )),
      );
    });

    test('rates 字段缺失时抛出 FormatException', () async {
      when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: ''),
          data: <String, dynamic>{},
          statusCode: 200,
        ),
      );

      expect(
        () => client.fetchRates('USD', '{base}'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('未包含 rates'),
        )),
      );
    });
  });
}
