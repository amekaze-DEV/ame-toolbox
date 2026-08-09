import 'package:flutter_test/flutter_test.dart';
import 'helpers/fake_storage_service.dart';
import 'package:shift_assistant_module/features/shift_assistant/models/shift_config.dart';
import 'package:shift_assistant_module/features/shift_assistant/services/holiday_data_service.dart';
import 'package:shift_assistant_module/features/shift_assistant/shift_assistant_module.dart';

void main() {
  group('ShiftAssistantModule', () {
    late FakeStorageService storage;
    late ShiftAssistantModule module;

    setUp(() async {
      storage = FakeStorageService();
      await storage.initialize();
      module = ShiftAssistantModule(
        holidayDataService: _FakeHolidayDataService(),
      );
      await module.initialize(storage);
    });

    tearDown(() async {
      await module.dispose();
    });

    test('definition has expected id and name', () {
      final definition = module.definition;
      expect(definition.id, 'shift_assistant');
      expect(definition.name, '倒班助手');
      expect(definition.iconName, 'shift');
    });

    test('summary returns primary rotation name after initialization', () {
      final summary = module.summary;
      expect(summary.label, '主要轮班');
      expect(summary.value, '我的轮班');
    });

    test('exportData includes module_shift_assistant_config', () {
      final data = module.exportData();
      expect(data.containsKey('module_shift_assistant_config'), true);
      expect(data['module_shift_assistant_config'] is Map<String, dynamic>, true);
    });

    test('importData updates config and reflects in summary', () async {
      final exported = module.exportData();
      final configJson =
          exported['module_shift_assistant_config'] as Map<String, dynamic>;

      configJson['rotations'] = [
        {
          'id': 'rotation_new',
          'name': '新轮班',
          'baseDate': '2026-08-01T00:00:00.000',
          'cycleDays': 1,
          'groups': [
            {
              'id': 'group_new',
              'name': '新班组',
              'colorValue': 0xFF_90A4AE,
            },
          ],
          'slots': [
            {'name': '白班', 'startTime': null, 'endTime': null, 'isRest': false},
          ],
          'assignments': [[0]],
          'isPrimary': true,
        },
      ];
      configJson['primaryRotationId'] = 'rotation_new';

      module.importData({'module_shift_assistant_config': configJson});
      expect(module.summary.value, '新轮班');
    });

    test('export/import roundtrip preserves config', () async {
      final exported = module.exportData();
      final configJson =
          exported['module_shift_assistant_config'] as Map<String, dynamic>;

      // 构造一个非默认配置，确保往返后能完整还原。
      configJson['rotations'] = [
        {
          'id': 'rotation_a',
          'name': '甲轮班',
          'baseDate': '2026-08-01T00:00:00.000',
          'cycleDays': 3,
          'groups': [
            {
              'id': 'group_a',
              'name': '甲班',
              'colorValue': 0xFF_7986CB,
            },
            {
              'id': 'group_b',
              'name': '乙班',
              'colorValue': 0xFF_4DB6AC,
            },
          ],
          'slots': [
            {
              'name': '白班',
              'startTime': '08:00',
              'endTime': '20:00',
              'isRest': false,
            },
            {
              'name': '夜班',
              'startTime': '20:00',
              'endTime': '08:00',
              'isRest': false,
            },
            {'name': '休息', 'startTime': null, 'endTime': null, 'isRest': true},
          ],
          'assignments': [
            [0, 1, 2],
            [1, 2, 0],
          ],
          'isPrimary': true,
        },
      ];
      configJson['primaryRotationId'] = 'rotation_a';

      // 将数据导入到一个全新模块实例，验证 summary 与再次导出一致。
      final newStorage = FakeStorageService();
      await newStorage.initialize();
      final newModule = ShiftAssistantModule(
        holidayDataService: _FakeHolidayDataService(),
      );
      await newModule.initialize(newStorage);

      newModule.importData({'module_shift_assistant_config': configJson});
      expect(newModule.summary.value, '甲轮班');

      // 等待 importData 内部异步 updateConfig 完成（Repository 保存后
      // notifyListeners），避免在 dispose 后再触发通知。
      await Future<void>.delayed(Duration.zero);

      final reExported = newModule.exportData();
      expect(
        reExported['module_shift_assistant_config'],
        equals(configJson),
      );

      await newModule.dispose();
    });
  });
}

/// 不发起网络请求的节假日数据服务占位实现。
class _FakeHolidayDataService extends HolidayDataService {
  _FakeHolidayDataService() : super(httpClient: null);

  @override
  Future<Map<String, HolidayInfo>> fetchYear(int year) async => {};
}
