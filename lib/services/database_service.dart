import 'package:hive/hive.dart';
import '../models/attendance_record.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  static const String _boxName = 'attendanceBox';

  static Future<List<AttendanceRecord>> getRecords() async {
    final box = Hive.box<AttendanceRecord>(_boxName);
    final records = box.values.toList();
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    _computeStatusesForRecords(records);
    return records;
  }

  static void _computeStatusesForRecords(List<AttendanceRecord> records) {
    final Map<String, AttendanceRecord?> dailyInOut = {};

    for (final record in records) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.timestamp);
      if (record.shiftType == 'CLOCK IN') {
        dailyInOut[dateKey] = record;
      } else if (record.shiftType == 'CLOCK OUT') {
        final inRecord = dailyInOut[dateKey];
        if (inRecord != null) {
          record.outTimestamp = record.timestamp;
          final outHour = record.timestamp.hour;

          if (outHour > 18) {
            record.outStatus = 'Overtime';
          } else if (outHour < 18) {
            record.outStatus = 'Early Out';
          } else {
            record.outStatus = 'Regular';
          }

          final inHour = inRecord.timestamp.hour;
          inRecord.status = inHour < 9 ? 'Present' : 'Late';

          inRecord.save();
          record.save();
        }
      }
    }
  }

  static Future<void> addRecord({
    required String imagePath,
    required String company,
    required String shiftType,
    required String location,
  }) async {
    final box = Hive.box<AttendanceRecord>(_boxName);
    final now = DateTime.now();
    final record = AttendanceRecord(
      id: now.millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      timestamp: now,
      company: company,
      shiftType: shiftType,
      location: location,
    );

    final dateKey = DateFormat('yyyy-MM-dd').format(now);

    if (shiftType == 'CLOCK IN') {
      final hour = now.hour;
      record.status = hour < 9 ? 'Present' : 'Late';
    } else if (shiftType == 'CLOCK OUT') {
      final inRecord = box.values.cast<AttendanceRecord>().firstWhereOrNull(
          (r) => r.shiftType == 'CLOCK IN' && DateFormat('yyyy-MM-dd').format(r.timestamp) == dateKey);

      if (inRecord != null) {
        final hour = now.hour;
        record.outStatus = hour > 18 ? 'Overtime' : (hour < 18 ? 'Early Out' : 'Regular');

        if (inRecord.status == null) {
          final inHour = inRecord.timestamp.hour;
          inRecord.status = inHour < 9 ? 'Present' : 'Late';
          inRecord.save();
        }
      }
    }

    await box.add(record);
  }

  static Future<void> clearRecords() async {
    final box = Hive.box<AttendanceRecord>(_boxName);
    await box.clear();
  }

  static Future<Map<String, int>> getAttendanceStats() async {
    final records = await getRecords();
    final stats = {
      'present': 0,
      'late': 0,
      'absent': 0,
      'overtime': 0,
      'earlyOut': 0,
      'regular': 0,
    };

    if (records.isEmpty) return stats;

    final Map<String, AttendanceRecord?> ins = {};

    for (final record in records) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.timestamp);
      if (record.shiftType == 'CLOCK IN') {
        ins[dateKey] = record;
      } else if (record.shiftType == 'CLOCK OUT') {
        // Wrapped with braces to fix lint errors
        if (record.outStatus == 'Overtime') {
          stats['overtime'] = stats['overtime']! + 1;
        } else if (record.outStatus == 'Early Out') {
          stats['earlyOut'] = stats['earlyOut']! + 1;
        } else {
          stats['regular'] = stats['regular']! + 1;
        }
      }
    }

    for (final inRecord in ins.values) {
      if (inRecord != null) {
        // Wrapped with braces to fix lint errors
        if (inRecord.status == 'Present') {
          stats['present'] = stats['present']! + 1;
        } else if (inRecord.status == 'Late') {
          stats['late'] = stats['late']! + 1;
        }
      }
    }

    final firstDate = records.last.timestamp;
    final lastDate = records.first.timestamp;
    final days = lastDate.difference(firstDate).inDays + 1;

    stats['absent'] = (days - ins.length).clamp(0, days);

    return stats;
  }

  static Future<int> getCompletedShifts() async {
    final records = await getRecords();
    if (records.isEmpty) return 0;

    final Set<String> dailyComplete = {};
    for (final record in records) {
      if (record.shiftType == 'CLOCK OUT') {
        dailyComplete.add(DateFormat('yyyy-MM-dd').format(record.timestamp));
      }
    }
    return dailyComplete.length;
  }
}

extension AttendanceIterableExtension on Iterable<AttendanceRecord> {
  AttendanceRecord? firstWhereOrNull(bool Function(AttendanceRecord element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}