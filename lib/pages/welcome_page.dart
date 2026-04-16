import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'home.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1, milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    // Auto navigate to home after 3.5s
    Future.delayed(const Duration(seconds: 3, milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const Home(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Brand gradient matching your reference images
    final List<Color> brandGradient = const [
      Color(0xFF8B80F8),
      Color(0xFFE580F8),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ValueListenableBuilder<Map<String, String>?>(
          valueListenable: UserService.userNotifier,
          builder: (context, user, child) {
            // Get the first name from the sign-in data, uppercase it to match "DOM" style
            final firstName = (user?['firstName'] ?? 'USER').toUpperCase();
            
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. "Welcome" in Cursive/Italic Gradient
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => LinearGradient(
                      colors: brandGradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: const Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 64, 
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Cursive', // Ensure you have a cursive font or use FontStyle.italic
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  
                  // 2. Name in Bold Block Gradient (Matches "DOM")
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => LinearGradient(
                      colors: brandGradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: Text(
                      firstName,
                      style: const TextStyle(
                        fontSize: 72, 
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        height: 0.9, // Pulls the text closer to the "Welcome"
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                  
                  // Subtle loading indicator at the bottom
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFC778FD),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}