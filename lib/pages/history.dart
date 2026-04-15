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
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
      body: Column(
        children: [
          // Stats Dashboard - Updated to include Overtime
          FutureBuilder<Map<String, int>>(
            future: DatabaseService.getAttendanceStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFFC778FD)),
                );
              }
              final stats = snapshot.data ?? {};
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E), 
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('PRESENT', stats['present'] ?? 0, const [Color(0xFF8B80F8), Color(0xFFE580F8)]),
                          _buildStatItem('ABSENT', stats['absent'] ?? 0, [Colors.redAccent, Colors.red.shade800]),
                          _buildStatItem('LATE', stats['late'] ?? 0, [const Color.fromARGB(255, 224, 197, 44), Colors.white70]),
                          _buildStatItem('OVERTIME', stats['overtime'] ?? 0, [const Color.fromARGB(255, 219, 215, 209), Colors.orange.shade800]),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<List<AttendanceRecord>>(
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
                            const Icon(Icons.history, color: Colors.white54, size: 80),
                            const SizedBox(height: 16),
                            Text(
                              isNew 
                                ? 'Welcome! Start your first clock-in' 
                                : 'No attendance history yet',
                              style: const TextStyle(color: Colors.white54, fontSize: 18),
                            ),
                            Text(
                              isNew 
                                ? 'Your attendance will appear here' 
                                : 'Clock in from Shift to start',
                              style: const TextStyle(color: Colors.white38, fontSize: 14),
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
                                      Row(
                                        children: [
                                          Text(
                                            record.shiftType,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC778FD), fontSize: 16),
                                          ),
                                          if (record.status != null) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: record.status == 'Present' ? Colors.green : Colors.orange,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                record.status!,
                                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                          if (record.outStatus != null) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: record.outStatus == 'Regular' ? Colors.green
                                                  : (record.outStatus == 'Overtime' ? Colors.red : Colors.orange),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                record.outStatus!,
                                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(record.company, style: const TextStyle(color: Colors.white70)),
                                      Text(record.location, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(timeStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build the individual vertical stat items
  Widget _buildStatItem(String label, int count, List<Color> gradientColors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9, // Slightly smaller to fit 4 items
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48, // Adjusted from 60 to 48 to fit 4 items on a row
              fontWeight: FontWeight.w300,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}