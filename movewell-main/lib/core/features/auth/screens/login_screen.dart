import 'package:flutter/material.dart';
import 'package:movewell/core/theme/colors.dart';
import 'package:movewell/core/features/auth/screens/signup_screen.dart';
import 'package:movewell/core/features/dashboard/screens/dashboard_screen.dart';
import 'package:movewell/core/features/doctor_dashboard/screens/doctor_dashboard_screen.dart';
import 'package:movewell/core/widgets/input_field.dart';
import 'package:movewell/core/widgets/primary_button.dart';
import 'package:provider/provider.dart';
import 'package:movewell/core/features/auth/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int _selectedRoleIndex = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email and password.')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    authProvider.setRole(_selectedRoleIndex == 0 ? 'patient' : 'doctor');
    final success = await authProvider.login(email, password);

    if (success && mounted) {
      final role = authProvider.userRole;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'doctor'
              ? const DoctorDashboardScreen()
              : const DashboardScreen(),
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed. Please try again.'),
          backgroundColor: AppColors.sos,
        ),
      );
    }
  }

  void _handleGoogleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Sign In coming soon')),
    );
  }

  void _handleAppleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Sign In coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/movewell_logo.png',
                  height: 150,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              const Text('Welcome Back',
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
              const SizedBox(height: 4),
              const Text('Continue your journey.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 24),

              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildRoleTab('Patient', 0),
                    _buildRoleTab('Doctor', 1),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text('Email or Mobile Number',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              InputField(
                hint: 'example@example.com',
                controller: _emailController,
              ),
              const SizedBox(height: 18),
              const Text('Password',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              InputField(
                hint: '••••••••••••', 
                isPassword: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reset password coming soon')),
                    );
                  },
                  child: const Text('Forgot Password?',
                    style: TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Log In',
                isLoading: isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 24),
              _buildDivider(),
              const SizedBox(height: 20),
              _buildSocialRow(context),
              const SizedBox(height: 28),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(
                      builder: (_) => const SignupScreen())),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 13,
                        color: AppColors.textMuted),
                      children: [
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(text: 'Sign Up',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String label, int index) {
    final isSelected = _selectedRoleIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRoleIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(children: const [
      Expanded(child: Divider(color: AppColors.border)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text('or log in with',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ),
      Expanded(child: Divider(color: AppColors.border)),
    ]);
  }

  Widget _buildSocialRow(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _socialButton('G', Colors.red, onTap: _handleGoogleSignIn),
      const SizedBox(width: 16),
      _socialButton('', Colors.black, isApple: true, onTap: _handleAppleSignIn),
    ]);
  }

  Widget _socialButton(String label, Color color,
      {bool isApple = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: isApple
              ? const Icon(Icons.apple, size: 24, color: Colors.black)
              : Text(label,
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: color)),
        ),
      ),
    );
  }
}