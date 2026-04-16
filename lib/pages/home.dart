import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
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

late List<Widget> _pages;

@override
  void initState() {
    super.initState();
    _pages = [
      _HomeContent(onSeeAll: () => setState(() => _currentIndex = 1)),
      const History(),
      const Calendar(),
      const Menu(),
    ];
  }

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
  final VoidCallback? onSeeAll;
  const _HomeContent({this.onSeeAll});

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
            final profilePic = UserService.profilePicNotifier.value ?? '';
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _showEditProfileDialog(context),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: profilePic.isNotEmpty ? FileImage(File(profilePic)) : null,
                        backgroundColor: Colors.white24,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFC778FD),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.black, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildProfileField(Icons.person, 'Name', fullName),
                _buildProfileField(Icons.email, 'Email', user['email'] ?? ''),
                _buildProfileField(Icons.business, 'Company', user['company'] ?? ''),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) async {
    final currentUser = UserService.userNotifier.value;
    final firstNameController = TextEditingController(text: currentUser?['firstName'] ?? '');
    final lastNameController = TextEditingController(text: currentUser?['lastName'] ?? '');
    final emailController = TextEditingController(text: currentUser?['email'] ?? '');
    final companyController = TextEditingController(text: currentUser?['company'] ?? '');
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final profilePicController = TextEditingController(text: currentUser?['profilePic'] ?? '');
    File? profileImage;

    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.black87,
          title: const Row(
            children: [
              Icon(Icons.edit, color: Color(0xFFC778FD)),
              SizedBox(width: 8),
              Text('Edit Profile', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      profileImage = File(pickedFile.path);
                      final dir = await getApplicationDocumentsDirectory();
                      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
                      final path = '${dir.path}/$fileName';
                      await profileImage!.copy(path);
                      profilePicController.text = path;
                      setDialogState(() {});
                    }
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: profileImage != null ? FileImage(profileImage!) : null,
                        backgroundColor: Colors.white24,
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: Icon(Icons.camera_alt, color: Color(0xFFC778FD), size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person, color: Color(0xFFC778FD)),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {},
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: Icon(Icons.person_outline, color: Color(0xFFC778FD)),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {},
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: Color(0xFFC778FD)),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {},
                ),
                const SizedBox(height: 12),
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
                  onChanged: (value) {},
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock, color: Color(0xFFC778FD)),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFC778FD)),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC778FD)),
              onPressed: () async {
                try {
                  await UserService.updateUser('firstName', firstNameController.text);
                  await UserService.updateUser('lastName', lastNameController.text);
                  await UserService.updateUser('email', emailController.text);
                  await UserService.updateUser('company', companyController.text);
                  if (profilePicController.text.isNotEmpty) {
                    await UserService.saveProfilePic(profilePicController.text);
                  }
                  if (newPasswordController.text.isNotEmpty && currentPasswordController.text.isNotEmpty) {
                    await AuthService.updatePassword(emailController.text, newPasswordController.text);
                  }
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
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
          ValueListenableBuilder<String?>(
            valueListenable: UserService.profilePicNotifier,
            builder: (context, profilePic, child) {
              return GestureDetector(
                onTap: () => _showProfileDialog(context),
                child: Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: profilePic != null && profilePic.isNotEmpty ? FileImage(File(profilePic)) : null,
                    backgroundColor: Colors.white24,
                    child: profilePic == null || profilePic.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                ),
              );
            },
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
                      final now = DateTime.now();
                      final hour = now.hour;
                      String greeting;
                      if (hour >= 18 || hour < 5) {
                        greeting = 'EVENING';
                      } else if (hour >= 12) {
                        greeting = 'AFTERNOON';
                      } else {
                        greeting = 'MORNING';
                      }
                      return Row(
                        children: [
                          _buildGradientText("$greeting, ", 32, brandGradient, isBold: true),
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
                  onTap: widget.onSeeAll,
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
                Row(
                  children: [
                    Text(record.shiftType, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    if (record.status != null) ...[
                      SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: record.status == 'Present' ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(record.status!, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ],
                    if (record.outStatus != null) ...[
                      SizedBox(width: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: record.outStatus == 'Regular' ? Colors.green 
                            : (record.outStatus == 'Overtime' ? Colors.red : Colors.orange),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(record.outStatus!, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
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

