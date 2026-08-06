import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lunar/lunar.dart';

import '../models/shift_config.dart';

/// 节假日数据服务。
///
/// 负责中国法定节假日与调休日数据的“本地兜底 + 多源在线更新”。
/// 在线源按优先级依次尝试，任一源成功即停止；全部失败时使用本地兜底数据。
class HolidayDataService {
  HolidayDataService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const _sourceTimeout = Duration(seconds: 10);

  /// 三源在线地址模板（按优先级）。
  static const List<String> _sourceUrls = [
    'https://raw.githubusercontent.com/NateScarlet/holiday-cn/master/{year}.json',
    'https://unpkg.com/holiday-calendar/data/CN/{year}.json',
    'https://cdn.jsdelivr.net/npm/chinese-days/dist/years/{year}.json',
  ];

  /// 获取 [year] 年的节假日数据映射。
  ///
  /// key 为 `yyyy-MM-dd`，value 为归一化后的 [HolidayInfo]。
  /// 在线任一源成功即返回；全部失败时回退到本地兜底。
  Future<Map<String, HolidayInfo>> fetchYear(int year) async {
    for (final urlTemplate in _sourceUrls) {
      final url = urlTemplate.replaceAll('{year}', year.toString());
      try {
        final result = await _fetchFromUrl(url);
        if (result.isNotEmpty) {
          return result;
        }
      } catch (_) {
        // 降级到下一个源。
      }
    }

    // 全部在线源失败，使用本地兜底。
    return _buildFallback(year);
  }

  Future<Map<String, HolidayInfo>> _fetchFromUrl(String url) async {
    final response = await _httpClient
        .get(Uri.parse(url))
        .timeout(_sourceTimeout);

    if (response.statusCode != 200) {
      return const {};
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // 根据返回结构自动选择解析器。
    if (json.containsKey('days')) {
      return _parseHolidayCn(json);
    }
    if (json.containsKey('dates')) {
      return _parseHolidayCalendar(json);
    }
    if (json.containsKey('holidays') || json.containsKey('workdays')) {
      return _parseChineseDays(json);
    }

    return const {};
  }

  /// 解析 NateScarlet/holiday-cn 格式。
  Map<String, HolidayInfo> _parseHolidayCn(Map<String, dynamic> json) {
    final days = json['days'] as List<dynamic>?;
    if (days == null) return const {};

    final result = <String, HolidayInfo>{};
    for (final item in days) {
      final map = item as Map<String, dynamic>;
      final date = map['date'] as String?;
      final name = map['name'] as String?;
      final isOffDay = map['isOffDay'] as bool? ?? false;
      if (date == null || name == null) continue;

      result[date] = HolidayInfo(
        name: name,
        isHoliday: isOffDay,
        isWorkday: !isOffDay,
      );
    }
    return result;
  }

  /// 解析 cg-zhou/holiday-calendar 格式。
  Map<String, HolidayInfo> _parseHolidayCalendar(Map<String, dynamic> json) {
    final dates = json['dates'] as List<dynamic>?;
    if (dates == null) return const {};

    final result = <String, HolidayInfo>{};
    for (final item in dates) {
      final map = item as Map<String, dynamic>;
      final date = map['date'] as String?;
      final name = map['name'] as String?;
      final type = map['type'] as String?;
      if (date == null || name == null || type == null) continue;

      final isHoliday = type == 'public_holiday';
      final isWorkday = type == 'transfer_workday';
      result[date] = HolidayInfo(
        name: name,
        isHoliday: isHoliday,
        isWorkday: isWorkday,
      );
    }
    return result;
  }

  /// 解析 Chinese Days 格式。
  Map<String, HolidayInfo> _parseChineseDays(Map<String, dynamic> json) {
    final result = <String, HolidayInfo>{};

    void parseSection(Map<String, dynamic> section, bool isHolidayFlag) {
      for (final entry in section.entries) {
        final date = entry.key;
        final value = entry.value;
        String? name;
        if (value is String) {
          final parts = value.split(',');
          name = parts.length >= 2 ? parts[1] : parts.first;
        } else if (value is Map<String, dynamic>) {
          name = value['name'] as String?;
        }
        if (name == null || name.isEmpty) continue;

        result[date] = HolidayInfo(
          name: name,
          isHoliday: isHolidayFlag,
          isWorkday: !isHolidayFlag,
        );
      }
    }

    final holidays = json['holidays'] as Map<String, dynamic>?;
    if (holidays != null) parseSection(holidays, true);

    final workdays = json['workdays'] as Map<String, dynamic>?;
    if (workdays != null) parseSection(workdays, false);

    return result;
  }

  /// 本地兜底：优先使用 lunar 包的 HolidayUtil， supplement 手动兜底。
  Map<String, HolidayInfo> _buildFallback(int year) {
    final result = <String, HolidayInfo>{};

    // lunar 包内置节假日数据。
    final lunarHolidays = HolidayUtil.getHolidaysByYear(year);
    for (final h in lunarHolidays) {
      result[h.getDay()] = HolidayInfo(
        name: h.getName(),
        isHoliday: !h.isWork(),
        isWorkday: h.isWork(),
      );
    }

    // 手动兜底补充（覆盖 lunar 包可能缺失的未来年份）。
    final manual = _manualFallback(year);
    for (final entry in manual.entries) {
      result.putIfAbsent(entry.key, () => entry.value);
    }

    return result;
  }

  /// 手动内置兜底数据：近三年主要节假日（当在线源与 lunar 均不可用时）。
  ///
  /// 注：未来年份数据为占位，确保应用不崩溃；准确数据依赖在线更新。
  Map<String, HolidayInfo> _manualFallback(int year) {
    final data = <int, Map<String, HolidayInfo>>{
      2027: {
        '2027-01-01': const HolidayInfo(name: '元旦', isHoliday: true),
        '2027-02-06': const HolidayInfo(name: '春节', isHoliday: true),
        '2027-02-07': const HolidayInfo(name: '春节', isHoliday: true),
        '2027-02-08': const HolidayInfo(name: '春节', isHoliday: true),
        '2027-02-09': const HolidayInfo(name: '春节', isHoliday: true),
        '2027-02-10': const HolidayInfo(name: '春节', isHoliday: true),
        '2027-02-11': const HolidayInfo(name: '春节', isHoliday: true),
        '2027-02-12': const HolidayInfo(name: '春节', isHoliday: true),
        '2027-04-05': const HolidayInfo(name: '清明', isHoliday: true),
        '2027-05-01': const HolidayInfo(name: '劳动节', isHoliday: true),
        '2027-05-03': const HolidayInfo(name: '劳动节', isHoliday: true),
        '2027-06-09': const HolidayInfo(name: '端午', isHoliday: true),
        '2027-09-15': const HolidayInfo(name: '中秋', isHoliday: true),
        '2027-10-01': const HolidayInfo(name: '国庆', isHoliday: true),
        '2027-10-02': const HolidayInfo(name: '国庆', isHoliday: true),
        '2027-10-03': const HolidayInfo(name: '国庆', isHoliday: true),
      },
    };
    return data[year] ?? const {};
  }
}
