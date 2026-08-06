import 'package:flutter/material.dart';

import '../models/shift_config.dart';
import '../services/holiday_data_service.dart';
import '../utils/date_utils.dart';
import 'shift_config_controller.dart';

/// 节假日数据状态。
///
/// 管理本地节假日缓存、后台更新状态，并按日期提供节假日信息。
class HolidayDataController extends ChangeNotifier {
  HolidayDataController({
    required this.service,
    required this.configController,
  });

  final HolidayDataService service;
  final ShiftConfigController configController;

  bool _isUpdating = false;

  /// 是否正在更新节假日数据。
  bool get isUpdating => _isUpdating;

  String? _lastError;

  /// 最近一次更新失败的错误信息；成功或从未更新时为 `null`。
  String? get lastError => _lastError;

  DateTime? get _lastUpdated => configController.config.holidaysLastUpdated;

  /// 节假日数据最后成功更新时间。
  DateTime? get lastUpdated => _lastUpdated;

  Map<String, HolidayInfo> get _cache => configController.config.holidayCache;

  /// 获取 [date] 当天的节假日信息；未缓存时返回 `null`。
  HolidayInfo? getHoliday(DateTime date) {
    final key = _dateKey(date);
    return _cache[key];
  }

  /// 检查并触发节假日数据更新。
  ///
  /// 若 [force] 为 true 则强制更新；否则仅在无数据或超过 [staleThreshold] 时更新。
  Future<void> checkAndUpdate({
    bool force = false,
    Duration staleThreshold = const Duration(hours: 24),
  }) async {
    final now = DateTime.now();
    final last = _lastUpdated;

    if (!force &&
        _cache.isNotEmpty &&
        last != null &&
        now.difference(last) < staleThreshold) {
      return;
    }

    await update();
  }

  /// 立即从在线源拉取并更新节假日缓存。
  Future<void> update() async {
    if (_isUpdating) return;

    _isUpdating = true;
    _lastError = null;
    notifyListeners();

    try {
      final currentYear = DateTime.now().year;
      final yearsToFetch = [currentYear - 1, currentYear, currentYear + 1];
      final merged = <String, HolidayInfo>{};

      for (final year in yearsToFetch) {
        final yearData = await service.fetchYear(year);
        merged.addAll(yearData);
      }

      final updatedConfig = configController.config.copyWith(
        holidayCache: merged,
        holidaysLastUpdated: DateTime.now(),
      );
      await configController.updateConfig(updatedConfig);
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  static String _dateKey(DateTime date) {
    final normalized = dateOnly(date);
    return '${normalized.year}-${_twoDigits(normalized.month)}-'
        '${_twoDigits(normalized.day)}';
  }

  static String _twoDigits(int n) => n >= 10 ? '$n' : '0$n';
}
