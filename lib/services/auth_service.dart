import 'package:hive/hive.dart';
import '../models/user.dart';

class AuthService {
  static const String _boxName = 'userBox';
  static Box<User>? _box;

  static Future<void> init() async {
    _box = await Hive.openBox<User>(_boxName);
  }

  static Future<User?> getUser(String email, String password) async {
    final box = _box;
    if (box == null) return null;
    
    return box.values.firstWhereOrNull((user) => 
      user.email == email && user.password == password
    );
  }

  static Future<bool> userExists(String email) async {
    final box = _box;
    if (box == null) return false;
    
    return box.values.any((user) => user.email == email);
  }

  static Future<void> registerUser(User user) async {
    final box = _box;
    if (box == null) throw Exception('AuthService not initialized');
    
    if (await userExists(user.email)) {
      throw Exception('User already exists');
    }
    
    await box.add(user);
  }

  static Future<void> deleteAllUsers() async { // For testing
    final box = _box;
    if (box != null) await box.clear();
  }

  static List<User> getAllUsers() {
    final box = _box;
    return box?.values.toList() ?? [];
  }

  static Future<void> updatePassword(String email, String newPassword) async {
    final box = _box;
    if (box == null) throw Exception('AuthService not initialized');
    
    final user = box.values.firstWhereOrNull((u) => u.email == email);
    if (user != null) {
      user.password = newPassword;
      await user.save();
    } else {
      throw Exception('User not found');
    }
  }
}

extension on Iterable<User> {
  User? firstWhereOrNull(bool Function(User element) test) {
    try {
      return firstWhere(test);
    } catch (_) {
      return null;
    }
  }
}

