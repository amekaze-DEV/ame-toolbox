import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:shift_assistant_module/core/storage/memory_storage_service.dart';
import 'package:shift_assistant_module/features/shift_assistant/data/shift_config_repository.dart';
import 'package:shift_assistant_module/features/shift_assistant/models/shift_config.dart';
import 'package:shift_assistant_module/features/shift_assistant/pages/shift_dashboard_page.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/holiday_data_controller.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/holiday_data_provider.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/shift_config_controller.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/shift_config_provider.dart';
import 'package:shift_assistant_module/features/shift_assistant/services/holiday_data_service.dart';

void main() {
  group('ShiftDashboardPage', () {
    testWidgets('renders date header and group shift cards',
        (tester) async {
      await _pumpDashboardPage(tester, _configWithTwoGroups());

      // 日期头显示当月当日。
      expect(find.textContaining(RegExp(r'\d+月\d+日')), findsOneWidget);
      // 农历信息。
      expect(find.textContaining('农历'), findsOneWidget);
      // 班组卡片。
      expect(find.text('甲班'), findsOneWidget);
      expect(find.text('乙班'), findsOneWidget);
      // 第一个班组高亮星标。
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('selecting date updates displayed date', (tester) async {
      await _pumpDashboardPage(tester, _configWithTwoGroups());

      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);

      // 选择 15 号。
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
      expect(find.textContaining('15日'), findsOneWidget);
    });

    testWidgets('go to today button returns to current date',
        (tester) async {
      await _pumpDashboardPage(tester, _configWithTwoGroups());

      // 先跳转到其他日期。
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      expect(find.textContaining('15日'), findsOneWidget);

      // 点击返回今天。
      await tester.tap(find.text('返回今天'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      expect(find.textContaining('${now.day}日'), findsOneWidget);
    });
  });
}

Future<void> _pumpDashboardPage(
  WidgetTester tester,
  ShiftConfig config,
) async {
  final storage = MemoryStorageService();
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
        mode: InputMode.mouse,
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
          ),
          home: const ShiftDashboardPage(),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

ShiftConfig _configWithTwoGroups() => ShiftConfig(
      rotations: [
        ShiftRotation(
          id: 'rotation_1',
          name: '测试轮班',
          baseDate: DateTime(2026, 8, 1),
          cycleCount: 1,
          groups: const [
            ShiftGroup(id: 'group_a', name: '甲班'),
            ShiftGroup(id: 'group_b', name: '乙班'),
          ],
          slots: const [
            ShiftSlot(name: '白班'),
            ShiftSlot(name: '夜班'),
            ShiftSlot(name: '休息'),
          ],
          assignments: const [
            [0, 1, 2],
            [1, 2, 0],
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
