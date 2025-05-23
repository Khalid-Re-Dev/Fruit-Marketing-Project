import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _navigating = false; // Flag to prevent multiple navigations

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Get auth service reference early
    final authService = Provider.of<AuthService>(context, listen: false);

    // Navigate to the appropriate screen after a delay
    Future.delayed(const Duration(seconds: 3), () async {
      // Check if widget is still mounted and not already navigating
      if (!mounted || _navigating) return;

      // Set flag to prevent multiple navigations
      setState(() {
        _navigating = true;
      });

      try {
        // Check authentication status
        final isAuthenticated = await authService.checkAuthentication();

        // Check again if widget is still mounted after async operation
        if (!mounted) return;

        // Navigate to appropriate screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) =>
                    isAuthenticated
                        ? const HomeScreen()
                        : const OnboardingScreen(),
          ),
        );
      } catch (e) {
        // Log error and navigate to onboarding as fallback
        debugPrint('Error during navigation: $e');

        // Check again if widget is still mounted
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
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
      backgroundColor: const Color(0xFFFF5722), // Orange background
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or icon
              Image.asset(
                'assets/images/logo.png',
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.restaurant,
                    size: 150,
                    color: Colors.white,
                  );
                },
              ),
              const SizedBox(height: 30),
              // App name with animated text
              AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Yum Bites',
                    textStyle: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    speed: const Duration(milliseconds: 200),
                  ),
                ],
                totalRepeatCount: 1,
              ),
              const SizedBox(height: 20),
              const Text(
                'Food For Everyone',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
