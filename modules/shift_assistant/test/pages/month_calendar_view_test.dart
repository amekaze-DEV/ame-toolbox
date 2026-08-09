import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import '../helpers/fake_storage_service.dart';
import 'package:shift_assistant_module/features/shift_assistant/data/shift_config_repository.dart';
import 'package:shift_assistant_module/features/shift_assistant/models/shift_config.dart';
import 'package:shift_assistant_module/features/shift_assistant/pages/month_calendar_view.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/holiday_data_controller.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/holiday_data_provider.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/shift_config_controller.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/shift_config_provider.dart';
import 'package:shift_assistant_module/features/shift_assistant/services/holiday_data_service.dart';

void main() {
  group('MonthCalendarView', () {
    testWidgets('renders weekday header and group chips',
        (tester) async {
      await _pumpCalendarView(tester, _configWithThreeGroups());

      expect(find.text('一'), findsOneWidget);
      expect(find.text('甲班'), findsWidgets);
      expect(find.text('乙班'), findsWidgets);
      expect(find.text('丙班'), findsWidgets);
    });

    testWidgets('uses horizontal scrolling on narrow widths',
        (tester) async {
      await _pumpCalendarView(
        tester,
        _configWithThreeGroups(),
        size: const Size(360, 600),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });
}

Future<void> _pumpCalendarView(
  WidgetTester tester,
  ShiftConfig config, {
  InputMode inputMode = InputMode.mouse,
  Size? size,
}) async {
  if (size != null) {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  final storage = FakeStorageService();
  await storage.initialize();

  final repository = ShiftConfigRepository(storage: storage);
  await repository.save(config);

  final configController = ShiftConfigController(repository: repository);
  await configController.load();

  final holidayController = HolidayDataController(
    service: _NoOpHolidayDataService(),
    configController: configController,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shiftConfigRepositoryProvider.overrideWithValue(repository),
        shiftConfigProvider.overrideWith((ref) => configController),
        holidayDataProvider.overrideWith((ref) => holidayController),
      ],
      child: InputModeScope(
        mode: inputMode,
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
          ),
          home: const Scaffold(body: MonthCalendarView()),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

ShiftConfig _configWithThreeGroups() => ShiftConfig(
      rotations: [
        ShiftRotation(
          id: 'rotation_1',
          name: '测试轮班',
          baseDate: DateTime(2026, 8, 1),
          cycleDays: 3,
          groups: const [
            ShiftGroup(id: 'group_a', name: '甲班'),
            ShiftGroup(id: 'group_b', name: '乙班'),
            ShiftGroup(id: 'group_c', name: '丙班'),
          ],
          slots: const [
            ShiftSlot(name: '白班'),
            ShiftSlot(name: '夜班'),
            ShiftSlot(name: '休息'),
          ],
          assignments: const [
            [0, 1, 2],
            [1, 2, 0],
            [2, 0, 1],
          ],
          isPrimary: true,
        ),
      ],
      primaryRotationId: 'rotation_1',
    );

/// 不发起网络请求的节假日数据服务占位实现。
class _NoOpHolidayDataService extends HolidayDataService {
  _NoOpHolidayDataService() : super(httpClient: null);

  @override
  Future<Map<String, HolidayInfo>> fetchYear(int year) async => {};
}
