// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'layout_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LayoutConfigAdapter extends TypeAdapter<LayoutConfig> {
  @override
  final int typeId = 3;

  @override
  LayoutConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LayoutConfig(
      autoBreakpoint: fields[0] == null ? true : fields[0] as bool,
      breakpoint: fields[1] == null ? 1.2 : fields[1] as double,
      autoDpi: fields[2] == null ? true : fields[2] as bool,
      dpiScale: fields[3] == null ? 1.0 : fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LayoutConfig obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.autoBreakpoint)
      ..writeByte(1)
      ..write(obj.breakpoint)
      ..writeByte(2)
      ..write(obj.autoDpi)
      ..writeByte(3)
      ..write(obj.dpiScale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayoutConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
