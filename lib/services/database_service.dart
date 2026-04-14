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

  /// Returns number of completed shifts (days with both CLOCK IN and CLOCK OUT)
  static Future<int> getCompletedShifts() async {
    final records = await getRecords();
    if (records.isEmpty) return 0;

    final Map<String, Set<String>> dailyShifts = {};
    
    for (final record in records) {
      final dateKey = '${record.timestamp.year}-${record.timestamp.month}-${record.timestamp.day}';
      dailyShifts.putIfAbsent(dateKey, () => <String>{}).add(record.shiftType);
    }
    
    int completed = 0;
    for (final shifts in dailyShifts.values) {
      if (shifts.contains('CLOCK IN') && shifts.contains('CLOCK OUT')) {
        completed++;
      }
    }
    
    return completed;
  }
}