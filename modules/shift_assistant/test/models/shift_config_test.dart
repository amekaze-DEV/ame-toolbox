import 'package:flutter_test/flutter_test.dart';
import 'package:shift_assistant_module/features/shift_assistant/models/shift_config.dart';

void main() {
  group('ShiftConfig', () {
    test('defaults creates primary rotation', () {
      final config = ShiftConfig.defaults();

      expect(config.rotations.length, 1);
      expect(config.primaryRotationId, isNotNull);
      expect(config.primaryRotation, isNotNull);
      expect(config.primaryRotation!.isPrimary, true);
    });

    test('orderedRotations places primary first', () {
      final first = ShiftRotation(
        id: 'r1',
        name: 'A',
        baseDate: DateTime(2026, 8, 1),
        cycleDays: 1,
        groups: const [ShiftGroup(id: 'g1', name: '一班')],
        slots: const [ShiftSlot(name: '白班')],
        assignments: const [[0]],
      );
      final second = first.copyWith(id: 'r2', name: 'B', isPrimary: true);
      final config = ShiftConfig(
        rotations: [first, second],
        primaryRotationId: 'r2',
      );

      expect(config.orderedRotations.first.id, 'r2');
    });

    test('findRotationById returns matching rotation', () {
      final config = ShiftConfig.defaults();
      final id = config.rotations.first.id;

      expect(config.findRotationById(id), isNotNull);
      expect(config.findRotationById('missing'), isNull);
    });

    test('toJson / fromJson roundtrip preserves data', () {
      final original = ShiftConfig.defaults();
      final json = original.toJson();
      final restored = ShiftConfig.fromJson(json);

      expect(restored.rotations.length, original.rotations.length);
      expect(restored.primaryRotationId, original.primaryRotationId);
      expect(restored.rotations.first.name, original.rotations.first.name);
      expect(
        restored.rotations.first.assignments,
        original.rotations.first.assignments,
      );
    });
  });

  group('ShiftRotation', () {
    final rotation = ShiftRotation(
      id: 'r1',
      name: '测试轮班',
      baseDate: _baseDate,
      cycleDays: 4,
      groups: const [
        ShiftGroup(id: 'g1', name: '一班'),
        ShiftGroup(id: 'g2', name: '二班'),
      ],
      slots: const [
        ShiftSlot(name: '白班'),
        ShiftSlot(name: '夜班'),
      ],
      assignments: const [
        [0, 1, 0, 1],
        [1, 0, 1, 0],
      ],
    );

    test('cycleDays returns configured value', () {
      expect(rotation.cycleDays, 4);
    });

    test('slotFor returns expected slot', () {
      expect(rotation.slotFor(0, 0).name, '白班');
      expect(rotation.slotFor(1, 0).name, '夜班');
      expect(rotation.slotFor(0, 2).name, '白班');
    });
  });
}

final _baseDate = DateTime(2026, 8, 1);
