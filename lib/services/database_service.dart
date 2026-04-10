import 'package:hive/hive.dart';
import '../models/attendance_record.dart';

class DatabaseService {
  static const String _boxName = 'attendanceBox';
  static DatabaseService? _instance;

  static Future<void> init() async {
    // No need for init, box opened in main
  }

  static DatabaseService get instance {
    if (_instance == null) {
      throw Exception('DatabaseService not initialized. Call init() first.');
    }
    return _instance!;
  }

  static Future<List<AttendanceRecord>> getRecords() async {
    final box = Hive.box<AttendanceRecord>(_boxName);
    final records = box.values.toList();
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    return records;
  }

  static Future<void> addRecord({
    required String imagePath,
    required String company,
    required String shiftType,
    required String location,
  }) async {
    final box = Hive.box<AttendanceRecord>(_boxName);
    final record = AttendanceRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID
      imagePath: imagePath,
      timestamp: DateTime.now(),
      company: company,
      shiftType: shiftType,
      location: location,
    );
    await box.add(record);
  }

  static Future<void> clearRecords() async {
    final box = Hive.box<AttendanceRecord>(_boxName);
    await box.clear();
  }
}
