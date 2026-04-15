import 'package:flutter/material.dart';
import 'dart:async';
import '../services/user_service.dart';
import '../services/database_service.dart';
import 'signin.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

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

Future<void> _showProfileDialog(BuildContext context) async {
    final user = await UserService.getUser();
    if (user == null) return;
    _firstNameController.text = user['firstName'] ?? '';
    _lastNameController.text = user['lastName'] ?? '';
    _emailController.text = user['email'] ?? '';
    _companyController.text = user['company'] ?? '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _firstNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lastNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _companyController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Company',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await UserService.updateUser('firstName', _firstNameController.text);
                await UserService.updateUser('lastName', _lastNameController.text);
                await UserService.updateUser('email', _emailController.text);
                await UserService.updateUser('company', _companyController.text);
                if (mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

Future<void> _showSettings(BuildContext context) async {
    final user = await UserService.getUser();
    _companyController.text = user?['company'] ?? '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _companyController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Company',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
            TextButton(
              onPressed: () async {
                await UserService.updateUser('company', _companyController.text);
                if (mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
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
        title: const Text('Menu', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ValueListenableBuilder<Map<String, String>?>(
        valueListenable: UserService.userNotifier,
        builder: (context, user, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile section
              Card(
                color: Colors.grey[900],
                child: ListTile(
                  leading: const Icon(Icons.person, color: Color(0xFFC778FD)),
                  title: Text(
                    user != null ? '${user['firstName']} ${user['lastName']}' : 'Guest',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    user?['email'] ?? '',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
                  onTap: () => _showProfileDialog(context),
                ),
              ),
              const SizedBox(height: 24),
              // Settings
              Card(
                color: Colors.grey[900],
                child: ListTile(
                  leading: const Icon(Icons.settings, color: Color(0xFFC778FD)),
                  title: const Text('Settings', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
                  onTap: () => _showSettings(context),
                ),
              ),
              const SizedBox(height: 24),
              // Logout
              Card(
                color: Colors.red[800],
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



  @override
  void dispose() {
    _companyController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}

