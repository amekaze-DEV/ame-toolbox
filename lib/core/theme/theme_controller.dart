import 'package:flutter/material.dart';

import 'package:ametoolbox/core/constants.dart';
import 'package:ametoolbox/core/models/theme_config.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

/// 主题状态管理（明暗、强调色、字体缩放）。
class ThemeController extends ChangeNotifier {
  ThemeController({required this._storage});

  final StorageService _storage;

  ThemeConfig _config = ThemeConfig();

  ThemeConfig get config => _config;

  Future<void> load() async {
    try {
      final stored = await _storage.getThemeConfig();
      if (stored != null) {
        _config = stored;
        notifyListeners();
      }
    } catch (_) {
      // 首次启动或存储未就绪时使用默认值。
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_config.mode == mode) return;
    _config.mode = mode;
    await _save();
    notifyListeners();
  }

  Future<void> setAccentColor(String hex) async {
    if (_config.accentColorHex == hex) return;
    _config.accentColorHex = hex;
    await _save();
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    final clamped = scale.clamp(AppConstants.minFontScale, AppConstants.maxFontScale);
    if ((_config.fontScale - clamped).abs() < 0.01) return;
    _config.fontScale = clamped;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      await _storage.setThemeConfig(_config);
    } catch (_) {
      // 存储未就绪时忽略。
    }
  }
}
