import 'dart:async';
import 'package:flutter/material.dart';
import 'package:movewell/core/theme/colors.dart';
import 'package:movewell/core/features/auth/screens/welcome_screen.dart';
import 'package:movewell/core/features/dashboard/screens/dashboard_screen.dart';
import 'package:movewell/core/features/doctor_dashboard/screens/doctor_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final navigator = Navigator.of(context);

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final savedRole = prefs.getString('user_role');

    if (token != null && token.isNotEmpty) {
      if (savedRole == 'doctor') {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const DoctorDashboardScreen()),
        );
      } else {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } else {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/movewell_logo.png',
              height: 120,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Recover Better. Move Smarter.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}