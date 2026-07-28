// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'module_definition.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ModuleDefinitionAdapter extends TypeAdapter<ModuleDefinition> {
  @override
  final int typeId = 1;

  @override
  ModuleDefinition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ModuleDefinition(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      iconName: fields[3] as String,
      defaultEnabled: fields[4] == null ? true : fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ModuleDefinition obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.iconName)
      ..writeByte(4)
      ..write(obj.defaultEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleDefinitionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
