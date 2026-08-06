import 'package:flutter_test/flutter_test.dart';
import 'package:shift_assistant_module/core/storage/memory_storage_service.dart';
import 'package:shift_assistant_module/features/shift_assistant/data/shift_config_repository.dart';
import 'package:shift_assistant_module/features/shift_assistant/providers/shift_config_controller.dart';

void main() {
  group('ShiftConfigController', () {
    late MemoryStorageService storage;
    late ShiftConfigRepository repository;
    late ShiftConfigController controller;

    setUp(() async {
      storage = MemoryStorageService();
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

    test('addRotationFromTemplate appends rotation and sets primary', () async {
      await controller.addRotationFromTemplate(
        templateId: 'template_3_2_single',
        name: '三班两倒',
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
