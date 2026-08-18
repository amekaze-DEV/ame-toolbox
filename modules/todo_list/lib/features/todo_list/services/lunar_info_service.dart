import 'package:lunar/lunar.dart';

/// 农历信息服务。
///
/// 封装 `lunar` 包，提供公历 → 农历日期、节气、干支、生肖查询。
/// 所有计算在本地完成，不依赖网络。
/// 实现参照倒班助手的 [LunarInfoService]，独立于待办模块内部使用。
class LunarInfoService {
  /// 获取指定日期的农历日期字符串，如“七月初一”。
  String getLunarDate(DateTime date) {
    final lunar = Lunar.fromDate(date);
    return '${lunar.getMonthInChinese()}${lunar.getDayInChinese()}';
  }

  /// 获取指定日期的节气/中气，如“立秋”。
  ///
  /// 无节气时返回 `null`。
  String? getSolarTerm(DateTime date) {
    final lunar = Lunar.fromDate(date);
    final jie = lunar.getJie();
    if (jie.isNotEmpty) return jie;
    final qi = lunar.getQi();
    if (qi.isNotEmpty) return qi;
    return null;
  }

  /// 获取指定日期的农历节日列表（如“春节”）。
  List<String> getLunarFestivals(DateTime date) {
    final lunar = Lunar.fromDate(date);
    return lunar.getFestivals();
  }

  /// 获取指定日期的公历节日列表（如“国庆节”、“教师节”、“母亲节”）。
  ///
  /// 覆盖固定日期节日与“第几个星期几”节日（父亲节、母亲节等）。
  List<String> getSolarFestivals(DateTime date) {
    final solar = Solar.fromDate(date);
    return solar.getFestivals();
  }

  /// 获取指定日期的干支纪年。
  String getYearGanZhi(DateTime date) {
    final lunar = Lunar.fromDate(date);
    return lunar.getYearInGanZhi();
  }

  /// 获取指定日期的生肖。
  String getShengXiao(DateTime date) {
    final lunar = Lunar.fromDate(date);
    return lunar.getYearShengXiao();
  }
}
