import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_module/features/calculator/data/calculator_config_repository.dart';
import 'package:calculator_module/features/calculator/models/calculator_type.dart';
import 'package:calculator_module/features/calculator/models/exchange_rate_cache.dart';
import 'package:calculator_module/features/calculator/providers/calculator_config_controller.dart';
import 'package:calculator_module/features/calculator/providers/exchange_rate_controller.dart';
import 'package:calculator_module/features/calculator/services/exchange_rate_client.dart';
import 'package:calculator_module/features/calculator/services/exchange_rate_service.dart';

import '../helpers/fake_storage_service.dart';

class _FakeClient implements ExchangeRateClient {
  final ExchangeRateResponse? response;
  final Exception? exception;

  _FakeClient({this.response, this.exception});

  @override
  Future<ExchangeRateResponse> fetchRates(
    String baseCurrency,
    String apiUrlTemplate,
  ) async {
    if (exception != null) throw exception!;
    if (response == null) throw Exception('未配置响应');
    return ExchangeRateResponse(
      baseCurrency: baseCurrency,
      rates: response!.rates,
      lastUpdated: response!.lastUpdated,
      sourceUrl: response!.sourceUrl.replaceAll(
        RegExp(r'/[A-Z]+$'),
        '/$baseCurrency',
      ),
    );
  }
}

void main() {
  group('ExchangeRateController', () {
    late FakeStorageService storage;
    late CalculatorConfigController configController;
    late ExchangeRateService service;

    setUp(() {
      storage = FakeStorageService();
      configController = CalculatorConfigController(
        repository: CalculatorConfigRepository(storage: storage),
      );
      service = ExchangeRateService(
        client: _FakeClient(
          response: ExchangeRateResponse(
            baseCurrency: 'USD',
            rates: {
              'CNY': 7.2,
              'EUR': 0.9,
              'JPY': 150.0,
            },
            lastUpdated: DateTime.utc(2026, 1, 1),
            sourceUrl: 'https://example.com/USD',
          ),
        ),
      );
    });

    Future<ExchangeRateController> createController() async {
      final controller = ExchangeRateController(
        service: service,
        configController: configController,
      );
      // 等待构造函数中可能触发的自动刷新完成。
      await controller.didInitialize;
      return controller;
    }

    test('默认货币为 USD 与 CNY', () async {
      final controller = await createController();
      expect(controller.fromCurrency, 'USD');
      expect(controller.toCurrency, 'CNY');
    });

    test('存在缓存时从缓存基准货币初始化', () async {
      await configController.setExchangeRates(
        ExchangeRateCache(
          baseCurrency: 'EUR',
          rates: {'USD': 1.1},
          lastUpdated: DateTime.utc(2026, 1, 1),
          sourceUrl: 'https://example.com/EUR',
        ),
      );
      final controller = await createController();
      expect(controller.fromCurrency, 'EUR');
    });

    test('设置金额后实时换算', () async {
      final controller = await createController();
      controller.setAmount('100');
      expect(controller.result, '720');
    });

    test('设置目标货币后重新换算', () async {
      final controller = await createController();
      controller.setAmount('100');
      controller.setToCurrency('JPY');
      expect(controller.result, '15000');
    });

    test('切换源货币后刷新并换算', () async {
      final controller = await createController();
      controller.setAmount('100');
      await controller.setFromCurrency('EUR');

      expect(controller.fromCurrency, 'EUR');
      expect(controller.status, ExchangeRateStatus.success);
      expect(controller.cache, isNotNull);
      expect(controller.cache!.baseCurrency, 'EUR');
    });

    test('网络失败时使用缓存并标记 offline', () async {
      await configController.setExchangeRates(
        ExchangeRateCache(
          baseCurrency: 'USD',
          rates: {'CNY': 7.0},
          lastUpdated: DateTime.utc(2026, 1, 1),
          sourceUrl: 'https://example.com/USD',
        ),
      );

      service = ExchangeRateService(
        client: _FakeClient(exception: Exception('network error')),
      );
      final controller = ExchangeRateController(
        service: service,
        configController: configController,
      );
      await controller.didInitialize;
      controller.setAmount('100');
      await controller.refresh();

      expect(controller.status, ExchangeRateStatus.offline);
      expect(controller.message, contains('离线缓存'));
      expect(controller.result, isNotEmpty);
    });

    test('无缓存且网络失败时显示错误', () async {
      service = ExchangeRateService(
        client: _FakeClient(exception: Exception('network error')),
      );
      final controller = ExchangeRateController(
        service: service,
        configController: configController,
      );
      await controller.didInitialize;
      controller.setAmount('100');
      await controller.refresh();

      expect(controller.status, ExchangeRateStatus.error);
      expect(controller.message, contains('暂无汇率数据'));
    });

    test('清空后金额与结果为空', () async {
      final controller = await createController();
      controller.setAmount('100');
      controller.clear();
      expect(controller.amount, '');
      expect(controller.result, '');
    });

    test('append 追加数字并实时换算', () async {
      final controller = await createController();
      controller.append('1');
      controller.append('0');
      controller.append('0');
      expect(controller.amount, '100');
      expect(controller.result, '720');
    });

    test('append 小数点规则正确', () async {
      final controller = await createController();
      controller.append('1');
      controller.append('.');
      controller.append('5');
      controller.append('.'); // 重复小数点无效
      expect(controller.amount, '1.5');
      expect(controller.result, '10.8');
    });

    test('backspace 删除金额末位', () async {
      final controller = await createController();
      controller.setAmount('100');
      controller.backspace();
      expect(controller.amount, '10');
      expect(controller.result, '72');
    });

    test('backspace 对空金额无操作', () async {
      final controller = await createController();
      controller.backspace();
      expect(controller.amount, '');
      expect(controller.result, '');
    });

    test('刷新成功后将缓存持久化到配置', () async {
      final controller = await createController();
      await controller.refresh();

      expect(configController.config.exchangeRates, isNotNull);
      expect(configController.config.exchangeRates!.baseCurrency, 'USD');
    });

    test('保存历史记录写入元数据', () async {
      final controller = await createController();
      controller.setAmount('100');
      await controller.saveToHistory();

      expect(configController.config.history, hasLength(1));
      final record = configController.config.history.first;
      expect(record.calculatorType, CalculatorType.exchangeRate);
      expect(record.metadata?['fromCurrency'], 'USD');
      expect(record.metadata?['toCurrency'], 'CNY');
      expect(record.metadata?['amount'], '100');
    });

    test('无结果时不写入历史记录', () async {
      final controller = await createController();
      await controller.saveToHistory();
      expect(configController.config.history, isEmpty);
    });

    test('交换货币后源与目标互换', () async {
      final controller = await createController();
      await controller.swap();

      expect(controller.fromCurrency, 'CNY');
      expect(controller.toCurrency, 'USD');
    });
  });
}
