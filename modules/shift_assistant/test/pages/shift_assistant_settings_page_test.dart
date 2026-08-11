import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/shared/widgets/adaptive_button.dart';
import '../helpers/fake_storage_service.dart';
import 'package:shift_assistant_module/features/shift_assistant/data/shift_config_repository.dart';
import 'package:shift_assistant_module/features/shift_assistant/models/shift_config.dart';
import 'package:shift_assistant_module/features/shift_assistant/pages/shift_assistant_settings_page.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/holiday_data_controller.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/holiday_data_provider.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/shift_config_controller.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/shift_config_provider.dart';
import 'package:shift_assistant_module/features/shift_assistant/services/holiday_data_service.dart';

void main() {
  group('ShiftAssistantSettingsPage', () {
    testWidgets('renders rotation management and holiday sections',
        (tester) async {
      await _pumpSettingsPage(tester, _defaultConfig());

      expect(find.text('轮班管理'), findsOneWidget);
      expect(find.text('节假日数据'), findsOneWidget);
      expect(find.text('我的轮班'), findsOneWidget);
    });

    testWidgets('adds rotation from dialog', (tester) async {
      await _pumpSettingsPage(tester, _defaultConfig());

      await tester.tap(find.widgetWithText(AdaptiveButton, '添加').first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('添加轮班'), findsOneWidget);

      // 第一个输入框为轮班名称。
      await tester.enterText(find.byType(TextField).first, '夜班轮班');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('夜班轮班'), findsOneWidget);
    });

    testWidgets('renders my team section and opens dialog', (tester) async {
      await _pumpSettingsPage(tester, _defaultConfig());

      expect(find.text('我的班组'), findsOneWidget);
      expect(find.text('未设置我的班组'), findsOneWidget);

      await tester.tap(find.widgetWithText(AdaptiveButton, '设置'));
      await tester.pumpAndSettle();

      expect(find.text('设置我的班组'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens edit rotation dialog without overflow',
        (tester) async {
      await _pumpSettingsPage(tester, _defaultConfig());

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      expect(find.text('编辑轮班'), findsOneWidget);
      expect(
        find.text('周期安排（行=班组，列=周期内第几天）'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('increasing cycle days resizes assignment matrix',
        (tester) async {
      await _pumpSettingsPage(tester, _defaultConfig());

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // 默认周期为 4 天。
      expect(find.text('D4'), findsOneWidget);
      expect(find.text('D5'), findsNothing);

      // 定位“循环周期天数”所在行，然后点击该行的增加按钮。
      final cycleDaysRow = find.ancestor(
        of: find.text('循环周期天数：'),
        matching: find.byType(Row),
      );
      final addCycleDaysButton = find.descendant(
        of: cycleDaysRow,
        matching: find.widgetWithIcon(IconButton, Icons.add),
      );
      await tester.tap(addCycleDaysButton);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('D5'), findsOneWidget);
    });
  });
}

Future<void> _pumpSettingsPage(
  WidgetTester tester,
  ShiftConfig config,
) async {
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
          home: const ShiftAssistantSettingsPage(),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

ShiftConfig _defaultConfig() => ShiftConfig.defaults();

/// 不发起网络请求的节假日数据服务占位实现。
class _NoOpHolidayDataService extends HolidayDataService {
  _NoOpHolidayDataService() : super(httpClient: null);

  @override
  Future<Map<String, HolidayInfo>> fetchYear(int year) async => {};
}
