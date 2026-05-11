import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:movewell/core/theme/colors.dart';
import 'package:movewell/core/widgets/header_background.dart';
import 'package:movewell/core/features/auth/providers/auth_provider.dart';
import 'package:movewell/core/features/auth/screens/welcome_screen.dart';
import 'package:movewell/core/services/doctor_service.dart';
import 'package:movewell/core/features/doctor_dashboard/screens/working_hours_screen.dart';
import 'package:movewell/core/features/doctor_dashboard/screens/notifications_screen.dart';
import 'package:movewell/core/features/doctor_dashboard/screens/account_security_screen.dart';
import 'package:movewell/core/features/doctor_dashboard/screens/help_support_screen.dart';

class DoctorProfileSettingsScreen extends StatefulWidget {
  const DoctorProfileSettingsScreen({super.key});

  @override
  State<DoctorProfileSettingsScreen> createState() => _DoctorProfileSettingsScreenState();
}

class _DoctorProfileSettingsScreenState extends State<DoctorProfileSettingsScreen> {
  final DoctorService _doctorService = DoctorService();
  int _totalPatients = 0;
  int _totalAppointments = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final patients = await _doctorService.getPatients();
      final appointments = await _doctorService.getSchedule();
      setState(() {
        _totalPatients = patients.length;
        _totalAppointments = appointments.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final doctorName = authProvider.userName;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const HeaderBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: AppColors.surface,
                                      child: const Icon(Icons.person,
                                          size: 60, color: AppColors.primary),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.background, width: 3),
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded,
                                          color: Colors.white, size: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  doctorName.isNotEmpty ? doctorName : 'Doctor',
                                  style: GoogleFonts.leagueSpartan(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lead Physiotherapist',
                                  style: GoogleFonts.leagueSpartan(
                                    fontSize: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: Color(0xFFFFB347), size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      '4.9',
                                      style: GoogleFonts.leagueSpartan(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(124 reviews)',
                                      style: GoogleFonts.leagueSpartan(
                                        fontSize: 13,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 15,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatItem(
                                          '$_totalPatients',
                                          'Patients',
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: AppColors.border,
                                      ),
                                      Expanded(
                                        child: _buildStatItem(
                                          '10+',
                                          'Years Exp.',
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: AppColors.border,
                                      ),
                                      Expanded(
                                        child: _buildStatItem(
                                          '$_totalAppointments',
                                          'Appointments',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Settings',
                                    style: GoogleFonts.leagueSpartan(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildSettingsOption(
                                  icon: Icons.schedule_outlined,
                                  title: 'Working Hours',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const WorkingHoursScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _buildSettingsOption(
                                  icon: Icons.notifications_outlined,
                                  title: 'Notifications',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _buildSettingsOption(
                                  icon: Icons.lock_outline,
                                  title: 'Account & Security',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AccountSecurityScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _buildSettingsOption(
                                  icon: Icons.language_outlined,
                                  title: 'Language',
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Language selection coming soon')),
                                    );
                                  },
                                ),
                                _buildSettingsOption(
                                  icon: Icons.help_outline,
                                  title: 'Help & Support',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const HelpSupportScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 32),

                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      await context.read<AuthProvider>().logout();
                                      if (!context.mounted) return;
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const WelcomeScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.sos,
                                      side: const BorderSide(
                                        color: AppColors.sos,
                                        width: 2,
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      'Log Out',
                                      style: GoogleFonts.leagueSpartan(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 100),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.leagueSpartan(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.leagueSpartan(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.leagueSpartan(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }
}