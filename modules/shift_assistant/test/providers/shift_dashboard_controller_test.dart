import 'package:flutter_test/flutter_test.dart';
import 'package:shift_assistant_module/core/storage/memory_storage_service.dart';
import 'package:shift_assistant_module/features/shift_assistant/data/shift_config_repository.dart';
import 'package:shift_assistant_module/features/shift_assistant/models/shift_config.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/holiday_data_controller.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/shift_config_controller.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/shift_dashboard_controller.dart';
import 'package:shift_assistant_module/features/shift_assistant/services/holiday_data_service.dart';
import 'package:shift_assistant_module/features/shift_assistant/services/lunar_info_service.dart';
import 'package:shift_assistant_module/features/shift_assistant/services/shift_schedule_service.dart';

class _FakeShiftConfigController extends ShiftConfigController {
  _FakeShiftConfigController._(ShiftConfigRepository repository)
      : super(repository: repository);

  factory _FakeShiftConfigController() {
    return _FakeShiftConfigController._(_FakeRepository());
  }

  @override
  ShiftConfig get config => _config;

  ShiftConfig _config = ShiftConfig.defaults();

  void setConfig(ShiftConfig value) => _config = value;
}

class _FakeRepository extends ShiftConfigRepository {
  _FakeRepository() : super(storage: _FakeStorage());

  @override
  Future<void> save(ShiftConfig config) async {}

  @override
  Future<ShiftConfig> load() async => ShiftConfig.defaults();
}

class _FakeStorage extends MemoryStorageService {}

class _FakeHolidayDataController extends HolidayDataController {
  _FakeHolidayDataController(ShiftConfigController configController)
      : super(
          service: HolidayDataService(),
          configController: configController,
        );
}

void main() {
  group('ShiftDashboardController', () {
    late _FakeShiftConfigController configController;
    late ShiftDashboardController dashboardController;

    setUp(() {
      configController = _FakeShiftConfigController();
      dashboardController = ShiftDashboardController(
        configController: configController,
        holidayController: _FakeHolidayDataController(configController),
        lunarService: LunarInfoService(),
        scheduleService: ShiftScheduleService(),
      );
    });

    test('dayInfo aggregates date, lunar and shifts', () {
      final dayInfo = dashboardController.dayInfo;
      expect(dayInfo.date.year, DateTime.now().year);
      expect(dayInfo.lunarDate.isNotEmpty, true);
      expect(dayInfo.groupShifts.length, 4);
    });

    test('selectDate updates selectedDate and notifies listeners', () {
      final initialDate = dashboardController.selectedDate;
      final target = initialDate.add(const Duration(days: 5));

      var notified = false;
      dashboardController.addListener(() => notified = true);

      dashboardController.selectDate(target);

      expect(dashboardController.selectedDate, target);
      expect(notified, true);
    });

    test('goToToday selects current date', () {
      dashboardController.selectDate(DateTime(2025, 1, 1));
      dashboardController.goToToday();
      expect(
        dashboardController.selectedDate,
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
      );
    });
  });
}
