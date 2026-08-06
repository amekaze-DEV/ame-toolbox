import 'package:flutter_test/flutter_test.dart';
import 'package:shift_assistant_module/core/storage/memory_storage_service.dart';
import 'package:shift_assistant_module/features/shift_assistant/data/shift_config_repository.dart';
import 'package:shift_assistant_module/features/shift_assistant/models/shift_config.dart';

void main() {
  group('ShiftConfigRepository', () {
    late MemoryStorageService storage;
    late ShiftConfigRepository repository;

    setUp(() async {
      storage = MemoryStorageService();
      await storage.initialize();
      repository = ShiftConfigRepository(storage: storage);
    });

    test('load returns defaults when no data exists', () async {
      final config = await repository.load();
      expect(config.rotations, isNotEmpty);
      expect(config.primaryRotation, isNotNull);
    });

    test('save and load roundtrip preserves custom config', () async {
      final custom = _customConfig();

      await repository.save(custom);
      final loaded = await repository.load();

      expect(loaded.rotations.length, 1);
      expect(loaded.primaryRotationId, 'rotation_a');
      expect(loaded.findRotationById('rotation_a')?.isPrimary, true);
      expect(loaded.findRotationById('rotation_a')?.cycleDays, 3);
      expect(loaded.holidayCache['2026-10-01']?.name, '国庆节');
      expect(loaded.holidaysLastUpdated, _epoch);
    });
  });
}

ShiftConfig _customConfig() => ShiftConfig(
      rotations: [
        ShiftRotation(
          id: 'rotation_a',
          name: '甲轮班',
          baseDate: _epoch,
          cycleCount: 1,
          groups: const [
            ShiftGroup(id: 'group_a', name: '甲班'),
            ShiftGroup(id: 'group_b', name: '乙班'),
            ShiftGroup(id: 'group_c', name: '丙班'),
          ],
          slots: const [
            ShiftSlot(name: '白班', startTime: '08:00', endTime: '20:00'),
            ShiftSlot(name: '夜班', startTime: '20:00', endTime: '08:00'),
            ShiftSlot(name: '休息', isRest: true),
          ],
          assignments: const [
            [0, 1, 2],
            [1, 2, 0],
            [2, 0, 1],
          ],
          isPrimary: true,
        ),
      ],
      primaryRotationId: 'rotation_a',
      holidayCache: const {
        '2026-10-01': HolidayInfo(name: '国庆节', isHoliday: true),
      },
      holidaysLastUpdated: _epoch,
    );

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);
