import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/user_service.dart';
import 'welcome_page.dart';

class Facialregistration extends StatefulWidget {
  const Facialregistration({super.key});

  @override
  State<Facialregistration> createState() => _FacialregistrationState();
}

class _FacialregistrationState extends State<Facialregistration> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  bool _isLoading = false;
  String? _error;

  final List<Color> brandGradient = const [
    Color(0xFF5A7AFF),
    Color(0xFFC778FD),
    Color(0xFFF2709C),
  ];

  Future<void> _captureFace() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        // Save to app docs dir with timestamp
        final appDir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final path = '${appDir.path}/profile_$timestamp.jpg';
        final savedFile = await File(image.path).copy(path);

        setState(() {
          _profileImage = savedFile;
        });

        // Save to UserService
        await UserService.saveProfilePic(savedFile.path);
        await UserService.completeFirstLogin();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Facial biometrics registered successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate to welcome page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WelcomePage()),
          );
        }
      } else {
        setState(() {
          _error = 'No image selected. Please try again.';
        });
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      setState(() {
        _error = 'Capture failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => LinearGradient(colors: brandGradient).createShader(bounds),
                child: const Text(
                  'FACIAL BIOMETRICS',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Register your face for contactless attendance',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              // Face preview/capture area
              GestureDetector(
                onTap: _isLoading ? null : _captureFace,
                child: Hero(
                  tag: 'face_preview',
                  child: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 5),
                      boxShadow: [
                        BoxShadow(
                          color: brandGradient.last.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: _profileImage != null
                        ? ClipOval(
                            child: Image.file(
                              _profileImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.person,
                                size: 100,
                                color: Colors.white54,
                              ),
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.face_retouching_natural,
                                size: 80,
                                color: Colors.white54,
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Tap to capture face',
                                style: TextStyle(color: Colors.white70, fontSize: 18),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // Capture button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isLoading 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.camera_alt, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Processing...' : 'Capture Face',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isLoading ? null : _captureFace,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: Colors.white54,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red[400]!, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

