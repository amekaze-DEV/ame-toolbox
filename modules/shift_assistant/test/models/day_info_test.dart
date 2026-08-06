import 'package:flutter_test/flutter_test.dart';
import 'package:shift_assistant_module/features/shift_assistant/models/day_info.dart';
import 'package:shift_assistant_module/features/shift_assistant/models/shift_config.dart';

void main() {
  group('DayInfo', () {
    test('copyWith updates selected fields', () {
      final dayInfo = DayInfo(
        date: DateTime(2026, 8, 5),
        groupShifts: {
          'group_a': const ShiftSlot(name: '白班'),
        },
      );

      final updated = dayInfo.copyWith(
        lunarDate: '七月初一',
        solarTerm: '立秋',
      );

      expect(updated.date, dayInfo.date);
      expect(updated.lunarDate, '七月初一');
      expect(updated.solarTerm, '立秋');
      expect(updated.groupShifts.length, 1);
    });

    test('shiftForGroup returns correct slot or null', () {
      const slot = ShiftSlot(name: '夜班');
      final dayInfo = DayInfo(
        date: DateTime(2026, 8, 5),
        groupShifts: {'group_a': slot},
      );

      expect(dayInfo.shiftForGroup('group_a'), slot);
      expect(dayInfo.shiftForGroup('group_b'), isNull);
    });
  });
}
