import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

import '../services/user_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'signin.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  static const Color _backgroundColor = Colors.black;
  static const Color _cardColor = Color(0xFF1E1E1E);
  static const Color _primaryAccent = Color(0xFFC778FD);
  static const Color _textColor = Colors.white;
  static const Color _subTextColor = Colors.white70;

  Future<void> _logout() async {
    await UserService.clearUser();
    await DatabaseService.clearRecords();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const Signin()),
          (route) => false,
        );
      }
    });
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: _cardColor,
        title: Row(
          children: [
            const Icon(Icons.person, color: _primaryAccent),
            const SizedBox(width: 8),
            const Text('Profile', style: TextStyle(color: _textColor)),
          ],
        ),
        content: ValueListenableBuilder<Map<String, String>?>(
          valueListenable: UserService.userNotifier,
          builder: (context, user, child) {
            if (user == null) {
              return const Text('No profile data', style: TextStyle(color: _textColor));
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
                        child: profilePic.isEmpty ? const Icon(Icons.person, size: 50, color: _textColor) : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: _primaryAccent,
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
          backgroundColor: _cardColor,
          // FIXED: Removed 'const' from Row (Line 124)
          title: Row(
            children: [
              const Icon(Icons.edit, color: _primaryAccent),
              const SizedBox(width: 8),
              const Text('Edit Profile', style: TextStyle(color: _textColor)),
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
                        child: Icon(Icons.camera_alt, color: _primaryAccent, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(firstNameController, 'First Name', Icons.person),
                const SizedBox(height: 12),
                _buildTextField(lastNameController, 'Last Name', Icons.person_outline),
                const SizedBox(height: 12),
                _buildTextField(emailController, 'Email', Icons.email),
                const SizedBox(height: 12),
                _buildTextField(companyController, 'Company', Icons.business),
                const SizedBox(height: 12),
                _buildTextField(currentPasswordController, 'Current Password', Icons.lock, obscure: true),
                const SizedBox(height: 12),
                _buildTextField(newPasswordController, 'New Password', Icons.lock_outline, obscure: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: _subTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryAccent),
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
                  if (context.mounted) Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: _textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _subTextColor),
        prefixIcon: Icon(icon, color: _primaryAccent),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white10,
      ),
    );
  }

  Widget _buildProfileField(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: _primaryAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: _subTextColor, fontSize: 12)),
                Text(value.isEmpty ? 'Not set' : value, style: const TextStyle(color: _textColor, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettings(BuildContext context) async {
    final user = await UserService.getUser();
    final companyController = TextEditingController(text: user?['company'] ?? '');

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardColor,
        // FIXED: Removed 'const' from Row (Line 264)
        title: Row(
          children: [
            const Icon(Icons.settings, color: _primaryAccent),
            const SizedBox(width: 8),
            const Text('Settings', style: TextStyle(color: _textColor, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(companyController, 'Company', Icons.business),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: _textColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryAccent),
            onPressed: () async {
              await UserService.updateUser('company', companyController.text);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings updated!')),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    companyController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Menu', style: TextStyle(color: _textColor, fontWeight: FontWeight.bold)),
        backgroundColor: _backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ValueListenableBuilder<Map<String, String>?>(
        valueListenable: UserService.userNotifier,
        builder: (context, user, child) {
          final profilePicNotifierValue = UserService.profilePicNotifier.value ?? '';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: _cardColor,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: profilePicNotifierValue.isNotEmpty ? FileImage(File(profilePicNotifierValue)) : null,
                    backgroundColor: Colors.white24,
                    child: profilePicNotifierValue.isEmpty ? const Icon(Icons.person, color: _textColor) : null,
                  ),
                  title: Text(
                    user != null ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim() : 'Guest',
                    style: const TextStyle(color: _textColor, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    user?['email'] ?? '',
                    style: const TextStyle(color: _subTextColor),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: _subTextColor, size: 16),
                  onTap: () => _showProfileDialog(context),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: _cardColor,
                child: ListTile(
                  leading: const Icon(Icons.settings, color: _primaryAccent),
                  title: const Text('Settings', style: TextStyle(color: _textColor)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: _subTextColor, size: 16),
                  onTap: () => _showSettings(context),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.red[900],
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text('Logout', style: TextStyle(color: Colors.white)),
                  onTap: () => _logout(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}