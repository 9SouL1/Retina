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

  ThemeData _fixedDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      // Using a dark grey for cards and surfaces to create depth against the black background
      cardColor: const Color(0xFF1E1E1E),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        contentTextStyle: TextStyle(color: Colors.white70),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFC778FD),
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
        onPrimary: Colors.black,
        secondary: Color(0xFFC778FD),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Colors.white,
        iconColor: Color(0xFFC778FD),
      ),
      // Ensures TextFields inside the app match the dark theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white10,
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Retina App',
      // Fixed to the dark theme configuration
      theme: _fixedDarkTheme(),
      themeMode: ThemeMode.dark,
      home: const IntroPage(),
    );
  }
}