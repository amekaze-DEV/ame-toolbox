import 'package:flutter_test/flutter_test.dart';
import '../helpers/fake_storage_service.dart';
import 'package:shift_assistant_module/features/shift_assistant/data/shift_config_repository.dart';
import 'package:shift_assistant_module/features/shift_assistant/models/shift_config.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/shift_config_controller.dart';

void main() {
  group('ShiftConfigController', () {
    late FakeStorageService storage;
    late ShiftConfigRepository repository;
    late ShiftConfigController controller;

    setUp(() async {
      storage = FakeStorageService();
      await storage.initialize();
      repository = ShiftConfigRepository(storage: storage);
      controller = ShiftConfigController(repository: repository);
      await controller.load();
    });

    test('load creates default rotation when storage is empty', () {
      expect(controller.config.rotations, isNotEmpty);
      expect(controller.config.primaryRotation, isNotNull);
    });

    test('setPrimaryRotation updates primary id and flags', () async {
      final first = controller.config.rotations.first;
      final secondRotation = first.copyWith(id: 'second');
      await controller.updateConfig(
        controller.config.copyWith(rotations: [first, secondRotation]),
      );

      await controller.setPrimaryRotation('second');

      expect(controller.config.primaryRotationId, 'second');
      expect(controller.config.findRotationById('second')?.isPrimary, true);
      expect(controller.config.findRotationById(first.id)?.isPrimary, false);
    });

    test('setPrimaryRotation no-op when already primary', () async {
      final rotation = controller.config.primaryRotation!;
      await controller.setPrimaryRotation(rotation.id);
      expect(controller.config.primaryRotationId, rotation.id);
    });

    test('clearPrimaryRotation removes primary designation', () async {
      await controller.clearPrimaryRotation();

      expect(controller.config.primaryRotationId, isNull);
      expect(
        controller.config.rotations.every((r) => !r.isPrimary),
        true,
      );
    });

    test('deleteRotation removes rotation and clears primary', () async {
      final rotation = controller.config.primaryRotation!;
      await controller.deleteRotation(rotation.id);

      expect(controller.config.findRotationById(rotation.id), isNull);
      expect(controller.config.primaryRotationId, isNull);
    });

    test('updateRotation persists name change', () async {
      final rotation = controller.config.primaryRotation!;
      final updated = rotation.copyWith(name: '改名后');

      await controller.updateRotation(updated);

      expect(controller.config.findRotationById(rotation.id)?.name, '改名后');
      final loaded = await repository.load();
      expect(loaded.findRotationById(rotation.id)?.name, '改名后');
    });

    test('addRotation appends rotation and sets primary', () async {
      await controller.addRotation(
        name: '三班两倒',
        baseDate: DateTime(2026, 8, 1),
        cycleDays: 3,
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
      );

      final added = controller.config.rotations.last;
      expect(added.name, '三班两倒');
      expect(added.groups.length, 3);
      expect(added.cycleDays, 3);
      expect(controller.config.primaryRotationId, added.id);
    });
  });
}
