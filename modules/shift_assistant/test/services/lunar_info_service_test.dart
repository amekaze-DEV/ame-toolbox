import 'package:flutter_test/flutter_test.dart';
import 'package:shift_assistant_module/features/shift_assistant/services/lunar_info_service.dart';

void main() {
  group('LunarInfoService', () {
    final service = LunarInfoService();

    test('getLunarDate returns Chinese lunar date', () {
      // 2026-08-03 is 六廿一 in lunar calendar.
      expect(service.getLunarDate(DateTime(2026, 8, 3)), '六廿一');
    });

    test('getSolarTerm returns solar term when present', () {
      // 2026-08-07 is 立秋.
      expect(service.getSolarTerm(DateTime(2026, 8, 7)), '立秋');
    });

    test('getSolarTerm returns null when no solar term', () {
      // 2026-08-03 has no solar term.
      expect(service.getSolarTerm(DateTime(2026, 8, 3)), isNull);
    });

    test('getLunarFestivals returns Spring Festival for lunar new year', () {
      // 2026-02-17 is Lunar New Year (春节).
      final festivals = service.getLunarFestivals(DateTime(2026, 2, 17));
      expect(festivals, contains('春节'));
    });

    test('getYearGanZhi returns gan-zhi for year', () {
      // 2026 is 丙午.
      expect(service.getYearGanZhi(DateTime(2026, 8, 3)), '丙午');
    });

    test('getShengXiao returns zodiac animal for year', () {
      // 2026 is Year of the Horse (马).
      expect(service.getShengXiao(DateTime(2026, 8, 3)), '马');
    });
  });
}
