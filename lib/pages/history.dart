import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../services/database_service.dart';
import '../services/user_service.dart';
import 'package:hive/hive.dart';
import 'dart:io';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Attendance History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
  body: FutureBuilder<List<AttendanceRecord>>(
        future: DatabaseService.getRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFC778FD)));
          }
          final records = snapshot.data ?? [];
if (records.isEmpty) {
            return FutureBuilder<bool>(
              future: UserService.isNewUser(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFC778FD)));
                }
                final isNew = snapshot.data ?? false;
                if (isNew) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await UserService.completeFirstLogin();
                    if (mounted) setState(() {});
                  });
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, color: Colors.white54, size: 80),
                      SizedBox(height: 16),
                      Text(
                        isNew 
                          ? 'Welcome! Start your first clock-in' 
                          : 'No attendance history yet',
                        style: TextStyle(color: Colors.white54, fontSize: 18),
                      ),
                      Text(
                        isNew 
                          ? 'Your attendance will appear here' 
                          : 'Clock in from Shift to start',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final timeStr = '${DateFormat('MMM dd, yyyy').format(record.timestamp)} at ${DateFormat('h:mm a').format(record.timestamp)}';
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(File(record.imagePath)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.shiftType,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC778FD), fontSize: 16),
                                ),
                                Text(record.company, style: const TextStyle(color: Colors.white70)),
                                Text(record.location, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(timeStr, style: TextStyle(color: Colors.white54, fontSize: 12)),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () async {
                          final box = Hive.box<AttendanceRecord>('attendanceBox');
                          await box.delete(record.key);
                          if (mounted) setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
