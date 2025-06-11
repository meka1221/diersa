import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:dearsa/auth/auth_service.dart'; // Updated for dearsa
import 'package:dearsa/screens/auth/login_screen.dart'; // Updated for dearsa
import 'package:dearsa/screens/home_screen.dart'; // Updated for dearsa
import 'package:dearsa/screens/onboarding_screen.dart'; // Updated for dearsa

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3)); // Имитация загрузки

    final hasSeenOnboarding = await _authService.hasSeenOnboarding();
    if (!mounted) return;

    if (!hasSeenOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    final isLoggedIn = await _authService.isLoggedIn();
    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset('assets/animations/loading.json', width: 200, height: 200),
      ),
    );
  }
}