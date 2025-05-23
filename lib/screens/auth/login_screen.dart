import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:food_delivery_app/screens/auth/register_screen.dart';
// import 'package:food_delivery_app/screens/home_screen.dart';
// import 'package:food_delivery_app/services/auth_service.dart';
// import 'package:food_delivery_app/widgets/custom_button.dart';
// import 'package:food_delivery_app/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Check internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      final hasConnection = result != ConnectivityResult.none;

      if (!hasConnection) {
        debugPrint('=== NO INTERNET CONNECTION ===');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No internet connection. Please check your network and try again.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      return hasConnection;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return true; // Assume online if we can't check
    }
  }

  Future<void> _login() async {
    debugPrint('=== LOGIN BUTTON PRESSED ===');

    // Validate form
    debugPrint('Validating login form...');
    final isValid = _formKey.currentState!.validate();
    debugPrint('Form validation result: ${isValid ? "VALID" : "INVALID"}');

    if (isValid) {
      // Check internet connectivity
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        debugPrint('Login aborted due to no internet connection');
        return;
      }

      // Get form values
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      debugPrint('Email entered: $email');
      debugPrint('Password length: ${password.length} characters');

      // Get auth service
      if (!mounted) return;
      debugPrint('Getting AuthService from Provider...');
      final authService = Provider.of<AuthService>(context, listen: false);

      // Attempt login
      debugPrint('Calling authService.signIn()...');
      final success = await authService.signIn(email, password);

      // Handle result
      debugPrint('Login result: ${success ? "SUCCESS" : "FAILURE"}');
      if (success) {
        debugPrint('User authenticated successfully');
        debugPrint(
          'User model: ${authService.userModel != null ? "EXISTS" : "NULL"}',
        );
      } else {
        debugPrint('Login failed with error: ${authService.error}');
      }

      if (success && mounted) {
        debugPrint('Navigating to HomeScreen...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (mounted) {
        debugPrint('Showing error snackbar...');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authService.error ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo or app name
                  const Text(
                    'Welcome Back',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Login to your account',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Email field
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Navigate to forgot password screen
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Login button
                  CustomButton(
                    text: 'Login',
                    isLoading: authService.isLoading,
                    onPressed: _login,
                  ),
                  const SizedBox(height: 20),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
