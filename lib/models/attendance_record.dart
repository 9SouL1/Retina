import 'package:hive/hive.dart';
part 'attendance_record.g.dart';

@HiveType(typeId: 0)
class AttendanceRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imagePath;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String company;

  @HiveField(4)
  final String shiftType;

  @HiveField(5)
  final String location;

  @HiveField(6)
  String? status; // Present, Late, Absent

  @HiveField(7)
  DateTime? outTimestamp;

  @HiveField(8)
  String? outStatus; // Regular, Overtime, EarlyOut

  AttendanceRecord({
    required this.id,
    required this.imagePath,
    required this.timestamp,
    required this.company,
    required this.shiftType,
    required this.location,
    this.status,
    this.outTimestamp,
    this.outStatus,
  });
}
