import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../services/database_service.dart';
import '../services/user_service.dart';
import '../models/attendance_record.dart';
import 'history.dart';
import 'calendar.dart';
import 'menu.dart';
import 'shift.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  final List<Color> brandGradient = const [
    Color(0xFF5A7AFF),
    Color(0xFFC778FD),
    Color(0xFFF2709C),
  ];

  final List<Widget> _pages = [
    _HomeContent(),
    History(),
    Calendar(),
    Menu(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: brandGradient),
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Shift()),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.camera_alt_outlined, size: 35, color: Colors.white),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  Icons.home_outlined,
                  color: _currentIndex == 0 ? Colors.white : Colors.white54,
                ),
                onPressed: () => setState(() => _currentIndex = 0),
              ),
              IconButton(
                icon: Icon(
                  Icons.history,
                  color: _currentIndex == 1 ? Colors.white : Colors.white54,
                ),
                onPressed: () => setState(() => _currentIndex = 1),
              ),
              const SizedBox(width: 40),
              IconButton(
                icon: Icon(
                  Icons.calendar_month_outlined,
                  color: _currentIndex == 2 ? Colors.white : Colors.white54,
                ),
                onPressed: () => setState(() => _currentIndex = 2),
              ),
              IconButton(
                icon: Icon(
                  Icons.menu,
                  color: _currentIndex == 3 ? Colors.white : Colors.white54,
                ),
                onPressed: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final List<Color> brandGradient = const [
    Color(0xFF5A7AFF),
    Color(0xFFC778FD),
    Color(0xFFF2709C),
  ];

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Row(
          children: [
            Icon(Icons.person, color: Color(0xFFC778FD)),
            SizedBox(width: 8),
            Text('Profile', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: ValueListenableBuilder<Map<String, String>?>( 
          valueListenable: UserService.userNotifier,
          builder: (context, user, child) {
            if (user == null) {
              return const Text('No profile data', style: TextStyle(color: Colors.white));
            }
            final fullName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileField(Icons.person, 'Name', fullName),
                _buildProfileField(Icons.email, 'Email', user['email'] ?? ''),
                _buildProfileField(Icons.business, 'Company', user['company'] ?? ''),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, color: Colors.black),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC778FD),
                    ),
                    onPressed: () => _showEditProfileDialog(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final currentUser = UserService.userNotifier.value;
    final nameController = TextEditingController(text: '${currentUser?['firstName'] ?? ''} ${currentUser?['lastName'] ?? ''}'.trim());
    final companyController = TextEditingController(text: currentUser?['company'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFFC778FD)),
            SizedBox(width: 8),
            Text('Edit Profile', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person, color: Color(0xFFC778FD)),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white10,
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                final names = value.trim().split(' ');
                UserService.updateUser('firstName', names.isNotEmpty ? names[0] : '');
                UserService.updateUser('lastName', names.length > 1 ? names.sublist(1).join(' ') : '');
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: companyController,
              decoration: const InputDecoration(
                labelText: 'Company',
                prefixIcon: Icon(Icons.business, color: Color(0xFFC778FD)),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white10,
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => UserService.updateUser('company', value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC778FD)),
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile saved!')),
              );
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC778FD)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(value.isEmpty ? 'Not set' : value, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Image.asset(
            'image/Logoretina.png',
            height: 48,
            width: 160,
            fit: BoxFit.contain,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
          GestureDetector(
            onTap: () => _showProfileDialog(context),
            child: const Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                radius: 18,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: Row(
                children: [
                  ValueListenableBuilder<Map<String, String>?>(
                    valueListenable: UserService.userNotifier,
                    builder: (context, user, child) {
                      final firstName = user?['firstName']?.toUpperCase() ?? 'USER';
                      return Row(
                        children: [
                          _buildGradientText("MORNING, ", 32, brandGradient, isBold: true),
                          _buildGradientText(firstName, 32, brandGradient, isBold: false),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildStatsCard(brandGradient),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ATTENDANCE HISTORY", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                GestureDetector(
                  onTap: () {
                    final homeState = context.findAncestorStateOfType<_HomeState>();
                    homeState?._currentIndex = 1;
                    homeState?.setState(() {});
                  },
                  child: _buildGradientText("SEE ALL", 14, brandGradient, isBold: true),
                ),
              ],
            ),
            FutureBuilder<List<AttendanceRecord>>(
              future: DatabaseService.getRecords(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final records = snapshot.data!;
                  if (records.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No recent attendance records',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: records.length > 4 ? 4 : records.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return _buildHistoryItem(record);
                    },
                  );
                }
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFC778FD))),
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(List<Color> brandGradient) {
    const int totalShifts = 25;
    return FutureBuilder<int>(
      future: DatabaseService.getCompletedShifts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withAlpha(25),
                    valueColor: AlwaysStoppedAnimation<Color>(brandGradient[1]),
                  ),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Calculating...", style: TextStyle(color: Colors.white, fontSize: 14)),
                      SizedBox(height: 20),
                      Text("Loading...", style: TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        final int completed = snapshot.data ?? 0;
        final double percentage = (completed / totalShifts) * 100;
        final double progressValue = (percentage / 100).clamp(0.0, 1.0);
        final bool isGreat = percentage >= 70;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: CircularProgressIndicator(
                      value: progressValue,
                      strokeWidth: 10,
                      backgroundColor: Colors.white.withAlpha(25),
                      valueColor: AlwaysStoppedAnimation<Color>(brandGradient[1]),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        completed == 0 ? "0%" : "${percentage.toStringAsFixed(0)}%",
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "$completed/$totalShifts",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        children: [
                          const TextSpan(text: "Wow your attendance percentage is "),
                          TextSpan(
                            text: isGreat ? "great" : "good",
                            style: TextStyle(
                              color: isGreat ? Color(0xFFC778FD) : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: "!"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "It's $completed/$totalShifts",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryItem(AttendanceRecord record) {
    final timeStr = DateFormat('h:mm a').format(record.timestamp);
    final statusColor = record.shiftType == 'CLOCK IN' ? Colors.pinkAccent : Colors.green;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: FileImage(File(record.imagePath)),
            radius: 25,
            backgroundColor: Colors.white24,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.location, style: const TextStyle(color: Colors.white, fontSize: 12)),
                Text(timeStr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(record.shiftType, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(record.company, style: const TextStyle(color: Color(0xFF616161), fontSize: 10)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              final homeState = context.findAncestorStateOfType<_HomeState>();
              homeState?._currentIndex = 1;
              homeState?.setState(() {});
            },
            child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientText(String text, double size, List<Color> brandGradient, {bool isBold = false}) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) => LinearGradient(colors: brandGradient).createShader(bounds),
      child: Text(text,
          style: TextStyle(
            fontSize: size, 
            fontWeight: isBold ? FontWeight.w900 : FontWeight.normal,
          )),
    );
  }
}

