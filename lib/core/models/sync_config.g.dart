// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncConfigAdapter extends TypeAdapter<SyncConfig> {
  @override
  final int typeId = 8;

  @override
  SyncConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncConfig(
      enabled: fields[0] == null ? false : fields[0] as bool,
      serverUrl: fields[1] == null ? '' : fields[1] as String,
      username: fields[2] == null ? '' : fields[2] as String,
      passwordEncrypted: fields[3] == null ? '' : fields[3] as String,
      frequency: fields[4] == null
          ? SyncFrequency.fiveMin
          : fields[4] as SyncFrequency,
      lastSyncTime: fields[5] as DateTime?,
      lastSyncStatus:
          fields[6] == null ? SyncStatus.idle : fields[6] as SyncStatus,
      moduleSectionEnabled:
          fields[7] == null ? true : fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SyncConfig obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.enabled)
      ..writeByte(1)
      ..write(obj.serverUrl)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.passwordEncrypted)
      ..writeByte(4)
      ..write(obj.frequency)
      ..writeByte(5)
      ..write(obj.lastSyncTime)
      ..writeByte(6)
      ..write(obj.lastSyncStatus)
      ..writeByte(7)
      ..write(obj.moduleSectionEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 6;

  @override
  SyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncStatus.idle;
      case 1:
        return SyncStatus.syncing;
      case 2:
        return SyncStatus.success;
      case 3:
        return SyncStatus.failed;
      default:
        return SyncStatus.idle;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    switch (obj) {
      case SyncStatus.idle:
        writer.writeByte(0);
        break;
      case SyncStatus.syncing:
        writer.writeByte(1);
        break;
      case SyncStatus.success:
        writer.writeByte(2);
        break;
      case SyncStatus.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncFrequencyAdapter extends TypeAdapter<SyncFrequency> {
  @override
  final int typeId = 7;

  @override
  SyncFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncFrequency.manual;
      case 1:
        return SyncFrequency.fiveMin;
      case 2:
        return SyncFrequency.fifteenMin;
      case 3:
        return SyncFrequency.sixtyMin;
      default:
        return SyncFrequency.manual;
    }
  }

  @override
  void write(BinaryWriter writer, SyncFrequency obj) {
    switch (obj) {
      case SyncFrequency.manual:
        writer.writeByte(0);
        break;
      case SyncFrequency.fiveMin:
        writer.writeByte(1);
        break;
      case SyncFrequency.fifteenMin:
        writer.writeByte(2);
        break;
      case SyncFrequency.sixtyMin:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
