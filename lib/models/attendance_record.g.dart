// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceRecordAdapter extends TypeAdapter<AttendanceRecord> {
  @override
  final int typeId = 0;

  @override
  AttendanceRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceRecord(
      id: fields[0] as String,
      imagePath: fields[1] as String,
      timestamp: fields[2] as DateTime,
      company: fields[3] as String,
      shiftType: fields[4] as String,
      location: fields[5] as String,
      status: fields[6] as String?,
      outTimestamp: fields[7] as DateTime?,
      outStatus: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.company)
      ..writeByte(4)
      ..write(obj.shiftType)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.outTimestamp)
      ..writeByte(8)
      ..write(obj.outStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
