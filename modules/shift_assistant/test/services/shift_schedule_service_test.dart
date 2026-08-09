import 'package:flutter_test/flutter_test.dart';
import 'package:shift_assistant_module/features/shift_assistant/models/shift_config.dart';
import 'package:shift_assistant_module/features/shift_assistant/services/shift_schedule_service.dart';

void main() {
  group('ShiftScheduleService', () {
    late ShiftScheduleService service;
    late ShiftRotation rotation;

    setUp(() {
      service = ShiftScheduleService();
      rotation = ShiftRotation(
        id: 'r1',
        name: '四班两倒单循环',
        baseDate: DateTime(2026, 5, 1),
        cycleDays: 4,
        groups: const [
          ShiftGroup(id: 'g1', name: '一班'),
          ShiftGroup(id: 'g2', name: '二班'),
          ShiftGroup(id: 'g3', name: '三班'),
          ShiftGroup(id: 'g4', name: '四班'),
        ],
        slots: const [
          ShiftSlot(name: '白班'),
          ShiftSlot(name: '上夜班'),
          ShiftSlot(name: '下夜班'),
          ShiftSlot(name: '休息'),
        ],
        assignments: const [
          [0, 1, 2, 3],
          [3, 0, 1, 2],
          [2, 3, 0, 1],
          [1, 2, 3, 0],
        ],
      );
    });

    test('calculateShiftsForDate returns slot for each group', () {
      final shifts = service.calculateShiftsForDate(rotation, DateTime(2026, 5, 1));

      expect(shifts['g1']?.name, '白班');
      expect(shifts['g2']?.name, '休息');
      expect(shifts['g3']?.name, '下夜班');
      expect(shifts['g4']?.name, '上夜班');
    });

    test('shifts repeat every cycleDays', () {
      final first = service.calculateShiftsForDate(rotation, DateTime(2026, 5, 1));
      final secondCycle = service.calculateShiftsForDate(
        rotation,
        DateTime(2026, 5, 5),
      );

      expect(secondCycle['g1']?.name, first['g1']?.name);
      expect(secondCycle['g2']?.name, first['g2']?.name);
    });

    test('negative offset handled correctly', () {
      final shifts = service.calculateShiftsForDate(
        rotation,
        DateTime(2026, 4, 30),
      );

      expect(shifts['g1']?.name, '休息');
    });

    test('buildDayInfo aggregates date and shifts', () {
      final dayInfo = service.buildDayInfo(
        rotation,
        DateTime(2026, 5, 1),
        lunarDate: '三月十五',
      );

      expect(dayInfo.date, DateTime(2026, 5, 1));
      expect(dayInfo.lunarDate, '三月十五');
      expect(dayInfo.groupShifts.length, 4);
      expect(dayInfo.shiftForGroup('g1')?.name, '白班');
    });

    test('slotNames returns rotation slot names in order', () {
      final names = service.slotNames(rotation);
      expect(names, ['白班', '上夜班', '下夜班', '休息']);
    });

    test('groupsWithSlot returns groups assigned to a slot', () {
      final dayInfo = service.buildDayInfo(rotation, DateTime(2026, 5, 1));
      final groups = service.groupsWithSlot(dayInfo, '白班', rotation);

      expect(groups.length, 1);
      expect(groups.first.name, '一班');
    });
  });
}
