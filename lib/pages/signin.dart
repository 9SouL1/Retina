import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'home.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class UserData {
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  const UserData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });
}

List<UserData> registeredUsers = [];

class WelcomeHomePage extends StatelessWidget {
  const WelcomeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromARGB(255, 2, 2, 2),
      body: Center(
        child: Text(
          "HOME PAGE",
          style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class WelcomePage extends StatefulWidget {
  final String firstName;
  const WelcomePage({super.key, required this.firstName});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  static const List<Color> brandGradient = [
    Color(0xFF5A7AFF),
    Color(0xFFC778FD),
    Color(0xFFF2709C),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    Timer(const Duration(seconds: 6), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGradientText("Welcome", 90, isScript: true, fontFamily: 'DancingScript'),
              const SizedBox(height: 10),
              _buildGradientText(widget.firstName.toUpperCase(), 110, isBold: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientText(String text, double size, {bool isBold = false, bool isScript = false, String? fontFamily}) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: brandGradient,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: size,
          fontStyle: isScript ? FontStyle.italic : FontStyle.normal,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w200,
          letterSpacing: isBold ? -5.0 : 0,
          height: 0.9,
          fontFamily: fontFamily,
        ),
      ),
    );
  }
}

// Rest of signin.dart unchanged...
class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoginPasswordVisible = false;

  static const List<Color> brandGradient = [
    Color(0xFF5A7AFF),
    Color(0xFFC778FD),
    Color(0xFFF2709C),
  ];

  Future<void> _login() async {
    String inputEmail = _userController.text.trim();
    String inputPassword = _passController.text.trim();

    UserData? user;
    for (final u in registeredUsers) {
      if (u.email == inputEmail && u.password == inputPassword) {
        user = u;
        break;
      }
    }
    if (user != null) {
      await UserService.saveUser(user.firstName, user.lastName, user.email, 'AppCase Inc.');
      if (mounted) {
        Navigator.push(
          context,
MaterialPageRoute(builder: (context) => WelcomePage(firstName: user!.firstName))
        );
      }
    } else {
      _showSnackBar('Invalid Email or Password', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGradientText("LET'S YOU IN", 38),
              const SizedBox(height: 50),
              _buildTextField("Email", _userController, isNameField: false),
              const SizedBox(height: 20),
              _buildPasswordField("Password", _passController, _isLoginPasswordVisible, 
                () => setState(() => _isLoginPasswordVisible = !_isLoginPasswordVisible)),
              const SizedBox(height: 40),
              _buildGradientButton("LOGIN", _login, width: 140),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Doesn't have account? ", style: TextStyle(color: Colors.white)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage())),
                    child: _buildGradientText("Create new", 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientText(String text, double size) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(colors: brandGradient).createShader(bounds),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {required bool isNameField}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      inputFormatters: isNameField ? [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))] : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFC778FD), width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String hint, TextEditingController controller, bool isVisible, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white60),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFC778FD), width: 2),
        ),
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed, {double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(colors: brandGradient),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _fName = TextEditingController();
  final TextEditingController _lName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final TextEditingController _confirmPass = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  static const List<Color> brandGradient = [
    Color(0xFF5A7AFF),
    Color(0xFFC778FD),
    Color(0xFFF2709C),
  ];

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _createAccount() async {
    if (_fName.text.trim().isEmpty || _lName.text.trim().isEmpty || !_isValidEmail(_email.text.trim()) || _pass.text.length < 6 || _pass.text != _confirmPass.text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check your fields. Password must be 6+ chars, valid email.'), backgroundColor: Colors.red),
      );
    }
    return;
    }

    registeredUsers.add(UserData(
      firstName: _fName.text.trim(),
      lastName: _lName.text.trim(),
      email: _email.text.trim(),
      password: _pass.text.trim(),
    )); 
    await UserService.saveUser(_fName.text.trim(), _lName.text.trim(), _email.text.trim(), 'AppCase Inc.'); 

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WelcomePage(firstName: _fName.text.trim())
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, top: 10),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGradientText("SIGN UP!", 45),
                  const SizedBox(height: 50),
                  Row(
                    children: [
                      Expanded(child: _buildTextField("First Name", _fName, isNameField: true)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTextField("Last Name", _lName, isNameField: true)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTextField("Email", _email, isNameField: false),
                  const SizedBox(height: 20),
                  _buildPasswordField("Password", _pass, _isPasswordVisible, 
                    () => setState(() => _isPasswordVisible = !_isPasswordVisible)),
                  const SizedBox(height: 20),
                  _buildPasswordField("Confirm Password", _confirmPass, _isConfirmPasswordVisible, 
                    () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible)),
                  const SizedBox(height: 60),
                  _buildGradientButton("Create", _createAccount, width: 200),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientText(String text, double size) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(colors: brandGradient).createShader(bounds),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {required bool isNameField}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      inputFormatters: isNameField ? [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))] : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFC778FD), width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String hint, TextEditingController controller, bool isVisible, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white60),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFC778FD), width: 2),
        ),
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed, {double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(colors: brandGradient),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}

