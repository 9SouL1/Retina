import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/intro.dart';
import 'models/attendance_record.dart';
import 'models/user.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(AttendanceRecordAdapter());
  Hive.registerAdapter(UserAdapter());
  await Hive.openBox<AttendanceRecord>('attendanceBox');
  await Hive.openBox<User>('userBox');
  await AuthService.init();
  await UserService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Retina App',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: const IntroPage(),
    );
  }
}
