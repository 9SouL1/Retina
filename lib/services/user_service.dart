import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class UserService {
  static ValueNotifier<Map<String, String>?> userNotifier = ValueNotifier(null);
  static ValueNotifier<String?> profilePicNotifier = ValueNotifier(null);


  static Future<void> init() async {
    final user = await getUser();
    userNotifier.value = user;
  }

  static Future<void> saveUser(String firstName, String lastName, String email, String company) async {
    final prefs = await SharedPreferences.getInstance();
await prefs.setString('firstName', firstName);
  await prefs.setString('lastName', lastName);
  await prefs.setString('email', email);
  await prefs.setString('company', company);
  if (!prefs.containsKey('firstLogin')) {
    await prefs.setBool('firstLogin', true);
  }
  userNotifier.value = await getUser();
  }

  static Future<Map<String, String>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('firstName')) return null;
    
    return {
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'email': prefs.getString('email') ?? '',
      'company': prefs.getString('company') ?? '',
    };
  }

  static Future<void> updateUser(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    userNotifier.value = await getUser();
  }

  static Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('email')) return null;
    return await getUser();
  }

  static Future<String?> getProfilePic() async {
    final prefs = await SharedPreferences.getInstance();
    final pic = prefs.getString('profile_pic');
    profilePicNotifier.value = pic;
    return pic;
  }

  static Future<void> saveProfilePic(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_pic', path);
    profilePicNotifier.value = path;
  }

static Future<void> clearUser() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('firstName');
  await prefs.remove('lastName');
  await prefs.remove('email');
  await prefs.remove('company');
  await prefs.remove('profile_pic');
  userNotifier.value = null;
}

static Future<bool> isNewUser() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('firstLogin') ?? false;
}

static Future<void> completeFirstLogin() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('firstLogin', false);
}

}
