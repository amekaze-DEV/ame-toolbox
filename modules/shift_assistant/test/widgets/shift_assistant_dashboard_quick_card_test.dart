import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import '../helpers/fake_storage_service.dart';
import 'package:shift_assistant_module/features/shift_assistant/data/shift_config_repository.dart';
import 'package:shift_assistant_module/features/shift_assistant/models/shift_config.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/holiday_data_controller.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/holiday_data_provider.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/shift_config_controller.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/shift_config_provider.dart';
import 'package:shift_assistant_module/features/shift_assistant/services/holiday_data_service.dart';
import 'package:shift_assistant_module/features/shift_assistant/widgets/shift_assistant_dashboard_quick_card.dart';

void main() {
  group('ShiftAssistantDashboardQuickCard', () {
    testWidgets('renders date info and current rotation when no my team',
        (tester) async {
      await _pumpQuickCard(tester, _defaultConfig());

      expect(find.text('倒班助手'), findsOneWidget);
      expect(find.text('今日'), findsOneWidget);
      expect(find.text('我的班组'), findsNothing);
      expect(find.textContaining('当前轮班'), findsOneWidget);
      expect(find.textContaining('一班'), findsWidgets);
    });

    testWidgets('shows my team section when my team is set', (tester) async {
      final config = _defaultConfig().copyWith(
        myTeamRotationId: 'rotation_1',
        myTeamGroupId: 'group_b',
      );

      await _pumpQuickCard(tester, config);

      expect(find.text('我的班组'), findsOneWidget);
      expect(find.textContaining('二班'), findsWidgets);
    });

    testWidgets('shows empty rotation hint when no rotations', (tester) async {
      await _pumpQuickCard(
        tester,
        const ShiftConfig(rotations: []),
      );

      expect(find.text('暂无轮班，请到设置页添加'), findsOneWidget);
    });

    testWidgets('tapping card triggers onOpenModule', (tester) async {
      var opened = false;
      await _pumpQuickCard(
        tester,
        _defaultConfig(),
        onOpenModule: () => opened = true,
      );

      await tester.tap(find.text('倒班助手'));
      await tester.pump();

      expect(opened, true);
    });
  });
}

Future<void> _pumpQuickCard(
  WidgetTester tester,
  ShiftConfig config, {
  VoidCallback onOpenModule = _noOp,
}) async {
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
        mode: InputMode.mouse,
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
          ),
          home: Scaffold(
            body: ShiftAssistantDashboardQuickCard(onOpenModule: onOpenModule),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void _noOp() {}

ShiftConfig _defaultConfig() => ShiftConfig(
      rotations: [
        ShiftRotation(
          id: 'rotation_1',
          name: '测试轮班',
          baseDate: DateTime(2026, 8, 1),
          cycleDays: 3,
          groups: const [
            ShiftGroup(id: 'group_a', name: '一班'),
            ShiftGroup(id: 'group_b', name: '二班'),
          ],
          slots: const [
            ShiftSlot(name: '白班'),
            ShiftSlot(name: '夜班'),
            ShiftSlot(name: '休息', isRest: true),
          ],
          assignments: const [
            [0, 1, 2],
            [1, 2, 0],
          ],
        ),
      ],
      lastViewedRotationId: 'rotation_1',
    );

/// 不发起网络请求的节假日数据服务占位实现。
class _NoOpHolidayDataService extends HolidayDataService {
  _NoOpHolidayDataService() : super(httpClient: null);

  @override
  Future<Map<String, HolidayInfo>> fetchYear(int year) async => {};
}
