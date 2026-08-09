import 'package:flutter_test/flutter_test.dart';
import '../helpers/fake_storage_service.dart';
import 'package:shift_assistant_module/features/shift_assistant/data/shift_config_repository.dart';
import 'package:shift_assistant_module/features/shift_assistant/models/shift_config.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/holiday_data_controller.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/shift_config_controller.dart';
import 'package:shift_assistant_module/features/shift_assistant/services/holiday_data_service.dart';

/// 不发起真实网络请求的 [HolidayDataService] 模拟。
class _FakeHolidayDataService extends HolidayDataService {
  final Map<int, Map<String, HolidayInfo>> _responses;

  _FakeHolidayDataService(this._responses);

  @override
  Future<Map<String, HolidayInfo>> fetchYear(int year) async {
    return _responses[year] ?? const {};
  }
}

void main() {
  group('HolidayDataController', () {
    late ShiftConfigController configController;

    setUp(() async {
      final storage = FakeStorageService();
      final repository = ShiftConfigRepository(storage: storage);
      configController = ShiftConfigController(repository: repository);
      await configController.load();
    });

    test('getHoliday returns cached holiday for date', () async {
      final service = _FakeHolidayDataService({
        2026: {
          '2026-01-01': const HolidayInfo(name: '元旦', isHoliday: true),
        },
      });
      final controller = HolidayDataController(
        service: service,
        configController: configController,
      );

      await controller.update();

      expect(controller.getHoliday(DateTime(2026, 1, 1))?.name, '元旦');
      expect(controller.getHoliday(DateTime(2026, 1, 2)), isNull);
    });

    test('checkAndUpdate skips when cache is fresh', () async {
      final currentYear = DateTime.now().year;
      final service = _FakeHolidayDataService({
        currentYear: {
          '$currentYear-01-01': const HolidayInfo(name: '元旦'),
        },
      });
      final controller = HolidayDataController(
        service: service,
        configController: configController,
      );

      await controller.update();
      final updatedAt = controller.lastUpdated;
      expect(updatedAt, isNotNull);

      await controller.checkAndUpdate();
      // 缓存仍新鲜，lastUpdated 应保持不变。
      expect(controller.lastUpdated, updatedAt);
    });

    test('update fetches surrounding years and persists cache', () async {
      final currentYear = DateTime.now().year;
      final service = _FakeHolidayDataService({
        currentYear - 1: {
          '$currentYear-01-01': const HolidayInfo(name: '去年'),
        },
        currentYear: {
          '$currentYear-06-01': const HolidayInfo(name: '今年'),
        },
        currentYear + 1: {
          '${currentYear + 1}-01-01': const HolidayInfo(name: '明年'),
        },
      });
      final controller = HolidayDataController(
        service: service,
        configController: configController,
      );

      expect(controller.isUpdating, false);

      final updateFuture = controller.update();
      expect(controller.isUpdating, true);
      await updateFuture;

      expect(controller.isUpdating, false);
      expect(controller.lastUpdated, isNotNull);
      expect(controller.lastError, isNull);
      expect(configController.config.holidayCache.length, 3);
    });

    test('force update bypasses freshness check', () async {
      final service = _FakeHolidayDataService({
        DateTime.now().year: {
          '${DateTime.now().year}-01-01': const HolidayInfo(name: '元旦'),
        },
      });
      final controller = HolidayDataController(
        service: service,
        configController: configController,
      );

      await controller.update();
      final firstUpdatedAt = controller.lastUpdated;

      // 稍微等待确保时间戳变化。
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await controller.checkAndUpdate(force: true);

      expect(controller.lastUpdated, isNot(firstUpdatedAt));
    });

    test('update records error when service fails', () async {
      final service = _ThrowingHolidayDataService();
      final controller = HolidayDataController(
        service: service,
        configController: configController,
      );

      await controller.update();

      expect(controller.isUpdating, false);
      expect(controller.lastError, isNotNull);
      expect(controller.lastUpdated, isNull);
    });

    test('checkAndUpdate fetches when cache is empty', () async {
      final currentYear = DateTime.now().year;
      final service = _FakeHolidayDataService({
        currentYear: {
          '$currentYear-01-01': const HolidayInfo(name: '元旦'),
        },
      });
      final controller = HolidayDataController(
        service: service,
        configController: configController,
      );

      expect(controller.lastUpdated, isNull);
      await controller.checkAndUpdate();
      expect(controller.lastUpdated, isNotNull);
    });
  });
}

/// 总是抛出异常的节假日数据服务，用于验证错误处理。
class _ThrowingHolidayDataService extends HolidayDataService {
  @override
  Future<Map<String, HolidayInfo>> fetchYear(int year) async {
    throw Exception('network error');
  }
}
