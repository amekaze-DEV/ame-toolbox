// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'module_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ModuleStateAdapter extends TypeAdapter<ModuleState> {
  @override
  final int typeId = 2;

  @override
  ModuleState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ModuleState(
      moduleId: fields[0] as String,
      enabled: fields[1] == null ? true : fields[1] as bool,
      displayOrder: fields[2] == null ? 0 : fields[2] as int,
      displayOrderLandscape: fields[3] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ModuleState obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.moduleId)
      ..writeByte(1)
      ..write(obj.enabled)
      ..writeByte(2)
      ..write(obj.displayOrder)
      ..writeByte(3)
      ..write(obj.displayOrderLandscape);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
