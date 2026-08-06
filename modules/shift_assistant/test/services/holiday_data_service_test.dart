import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shift_assistant_module/features/shift_assistant/services/holiday_data_service.dart';

/// 可编程的 [http.Client] 模拟，仅响应对应 [url] 的 GET 请求。
class _FakeHttpClient implements http.Client {
  _FakeHttpClient(this._handler);

  final http.Response? Function(String url) _handler;

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final response = _handler(url.toString());
    if (response == null) {
      return http.Response('{}', 404);
    }
    return response;
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw UnimplementedError();
  }

  @override
  void close() {}
}

void main() {
  group('HolidayDataService', () {
    test('parses holiday-cn format and normalizes to HolidayInfo', () async {
      final client = _FakeHttpClient((url) {
        if (url.contains('NateScarlet')) {
          return http.Response.bytes(
            utf8.encode(jsonEncode({
              'days': [
                {'date': '2026-01-01', 'name': '元旦', 'isOffDay': true},
                {'date': '2026-01-02', 'name': '元旦', 'isOffDay': true},
                {'date': '2026-02-15', 'name': '春节', 'isOffDay': false},
              ],
            })),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return null;
      });

      final service = HolidayDataService(httpClient: client);
      final result = await service.fetchYear(2026);

      expect(result['2026-01-01']?.name, '元旦');
      expect(result['2026-01-01']?.isHoliday, true);
      expect(result['2026-01-01']?.isWorkday, false);
      expect(result['2026-02-15']?.isHoliday, false);
      expect(result['2026-02-15']?.isWorkday, true);
    });

    test('parses holiday-calendar format', () async {
      final client = _FakeHttpClient((url) {
        if (url.contains('NateScarlet')) {
          return http.Response('{}', 404);
        }
        if (url.contains('holiday-calendar')) {
          return http.Response.bytes(
            utf8.encode(jsonEncode({
              'dates': [
                {'date': '2026-05-01', 'name': '劳动节', 'type': 'public_holiday'},
                {'date': '2026-05-02', 'name': '劳动节补班', 'type': 'transfer_workday'},
              ],
            })),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return null;
      });

      final service = HolidayDataService(httpClient: client);
      final result = await service.fetchYear(2026);

      expect(result['2026-05-01']?.isHoliday, true);
      expect(result['2026-05-01']?.isWorkday, false);
      expect(result['2026-05-02']?.isHoliday, false);
      expect(result['2026-05-02']?.isWorkday, true);
    });

    test('parses chinese-days format', () async {
      final client = _FakeHttpClient((url) {
        if (url.contains('NateScarlet') || url.contains('holiday-calendar')) {
          return http.Response('{}', 404);
        }
        if (url.contains('chinese-days')) {
          return http.Response.bytes(
            utf8.encode(jsonEncode({
              'holidays': {
                '2026-06-19': 'Dragon Boat Festival,端午,1',
              },
              'workdays': {
                '2026-06-20': 'Dragon Boat Festival,端午调休,1',
              },
            })),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return null;
      });

      final service = HolidayDataService(httpClient: client);
      final result = await service.fetchYear(2026);

      expect(result['2026-06-19']?.name, '端午');
      expect(result['2026-06-19']?.isHoliday, true);
      expect(result['2026-06-20']?.name, '端午调休');
      expect(result['2026-06-20']?.isWorkday, true);
    });

    test('falls back to local data when all online sources fail', () async {
      final client = _FakeHttpClient((url) => http.Response('{}', 500));

      final service = HolidayDataService(httpClient: client);
      final result = await service.fetchYear(2026);

      // lunar 包内置数据或手动兜底应包含主要节假日。
      expect(result.isNotEmpty, true);
      expect(result['2026-01-01']?.name, '元旦节');
    });

    test('fallback merges manual data for future years', () async {
      final client = _FakeHttpClient((url) => http.Response('{}', 500));

      final service = HolidayDataService(httpClient: client);
      final result = await service.fetchYear(2027);

      expect(result['2027-01-01']?.name, '元旦');
      expect(result['2027-01-01']?.isHoliday, true);
    });
  });
}
