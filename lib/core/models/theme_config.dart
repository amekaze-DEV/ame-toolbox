import 'package:hive/hive.dart';

part 'theme_config.g.dart';

/// 主题模式。
@HiveType(typeId: 4)
enum AppThemeMode {
  @HiveField(0)
  light,

  @HiveField(1)
  dark,
}

/// 主题配置数据。
@HiveType(typeId: 5)
class ThemeConfig {
  ThemeConfig({
    this.mode = AppThemeMode.light,
    this.accentColorHex = '#E85D04',
    this.fontScale = 1.0,
  });

  @HiveField(0, defaultValue: AppThemeMode.light)
  AppThemeMode mode;

  @HiveField(1, defaultValue: '#E85D04')
  String accentColorHex;

  @HiveField(2, defaultValue: 1.0)
  double fontScale;
}
