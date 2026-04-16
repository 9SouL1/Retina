import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'home.dart';
import 'facialregistration.dart';


class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isPasswordVisible = false;

  final List<Color> brandGradient = const [
    Color(0xFF5A7AFF),
    Color(0xFFC778FD),
    Color(0xFFF2709C),
  ];

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter email and password', Colors.orange);
      return;
    }

    try {
      final user = await AuthService.getUser(email, password);
      if (user != null) {
        await UserService.saveUser(user.firstName, user.lastName, user.email, 'AppCase Inc.');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
          );
        }
      } else {
        _showSnackBar('Invalid credentials', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Login error: $e', Colors.red);
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
              _buildTextField("Email", _emailController),
              const SizedBox(height: 20),
              _buildPasswordField("Password", _passController, _isPasswordVisible, 
                () => setState(() => _isPasswordVisible = !_isPasswordVisible)),
              const SizedBox(height: 40),
              _buildGradientButton("LOGIN", _login, width: 140),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have account? ", 
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const SignUpPage())
                    ),
                    child: const Text(
                      "Create new",
                      style: TextStyle(
                        color: Color(0xFFC778FD),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
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

  final List<Color> brandGradient = const [
    Color(0xFF5A7AFF),
    Color(0xFFC778FD),
    Color(0xFFF2709C),
  ];

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _createAccount() async {
    final firstName = _fName.text.trim();
    final lastName = _lName.text.trim();
    final email = _email.text.trim();
    final password = _pass.text.trim();
    final confirmPass = _confirmPass.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || !_isValidEmail(email) || password.length < 6 || password != confirmPass) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please check your fields. Password must be 6+ chars, valid email.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      final user = User(firstName: firstName, lastName: lastName, email: email, password: password);
      await AuthService.registerUser(user);
      await UserService.saveUser(firstName, lastName, email, 'AppCase Inc.');
      await UserService.completeFirstLogin();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Facialregistration()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration error: $e'), backgroundColor: Colors.red),
        );
      }
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
                  _buildTextField("Email", _email),
                  const SizedBox(height: 20),
                  _buildPasswordField("Password", _pass, _isPasswordVisible, 
                    () => setState(() => _isPasswordVisible = !_isPasswordVisible)),
                  const SizedBox(height: 20),
                  _buildPasswordField("Confirm Password", _confirmPass, _isConfirmPasswordVisible, 
                    () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible)),
                  const SizedBox(height: 60),
                  _buildGradientButton("CREATE", _createAccount, width: 200),
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
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 45, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {bool isNameField = false}) {
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

