// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ThemeConfigAdapter extends TypeAdapter<ThemeConfig> {
  @override
  final int typeId = 5;

  @override
  ThemeConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThemeConfig(
      mode: fields[0] == null ? AppThemeMode.light : fields[0] as AppThemeMode,
      accentColorHex: fields[1] == null ? '#E85D04' : fields[1] as String,
      fontScale: fields[2] == null ? 1.0 : fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ThemeConfig obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.mode)
      ..writeByte(1)
      ..write(obj.accentColorHex)
      ..writeByte(2)
      ..write(obj.fontScale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppThemeModeAdapter extends TypeAdapter<AppThemeMode> {
  @override
  final int typeId = 4;

  @override
  AppThemeMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AppThemeMode.light;
      case 1:
        return AppThemeMode.dark;
      default:
        return AppThemeMode.light;
    }
  }

  @override
  void write(BinaryWriter writer, AppThemeMode obj) {
    switch (obj) {
      case AppThemeMode.light:
        writer.writeByte(0);
        break;
      case AppThemeMode.dark:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppThemeModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
