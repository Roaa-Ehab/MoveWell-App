import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:movewell/core/theme/colors.dart';
import 'package:movewell/core/widgets/header_background.dart';
import 'package:movewell/core/features/auth/providers/auth_provider.dart';
import 'package:movewell/core/services/patient_service.dart';
import 'package:movewell/core/features/exercises/screens/exercises_screen.dart';
import 'package:movewell/core/features/doctor_profile/screens/doctor_profile_screen.dart';
import 'package:movewell/core/features/history/screens/history_screen.dart';
import 'package:movewell/core/features/profile/screens/profile_screen.dart';
import 'package:movewell/core/features/weekly_plan/screens/weekly_plan_screen.dart';
import 'package:movewell/core/features/video_session/screens/upcoming_sessions_screen.dart';
import 'package:movewell/core/features/chat/screens/chat_screen.dart';
import 'package:movewell/core/features/medical_reports/screens/medical_reports_screen.dart';
import 'package:movewell/core/features/timeline/screens/timeline_screen.dart';
import 'package:movewell/core/features/in_house_care/screens/in_house_care_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final PatientService _patientService = PatientService();
  List<dynamic> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final exercises = await _patientService.getExercises();
      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardContent(context),
          const DoctorProfileScreen(),
          const UpcomingSessionsScreen(),
          const HistoryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: buildBottomNav(),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    return Stack(
      children: [
        const HeaderBackground(),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              buildHeaderTopArea(),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else ...[
                          buildGreeting(),
                          const SizedBox(height: 24),
                          buildTodayCard(context),
                          const SizedBox(height: 28),
                          Text(
                            'Categories',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          buildCategories(context),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildHeaderTopArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final month = months[now.month - 1];
    final day = now.day;
    String suffix = 'th';
    if (day % 10 == 1 && day != 11) {
      suffix = 'st';
    } else if (day % 10 == 2 && day != 12) {
      suffix = 'nd';
    } else if (day % 10 == 3 && day != 13) {
      suffix = 'rd';
    }
    return '$day$suffix of $month';
  }

  Widget buildGreeting() {
    final authProvider = Provider.of<AuthProvider>(context);
    final firstName = authProvider.userName.split(' ')[0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good Morning, $firstName',
          style: GoogleFonts.leagueSpartan(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getFormattedDate(),
          style: GoogleFonts.leagueSpartan(
            color: AppColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget buildTodayCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Today's Plan",
            style: GoogleFonts.leagueSpartan(
              fontSize: 18,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_exercises.length} exercises available',
            style: GoogleFonts.leagueSpartan(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExercisesScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              elevation: 0,
            ),
            child: Text(
              'Start Exercises',
              style: GoogleFonts.leagueSpartan(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCategories(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'icon': Icons.timeline, 'label': 'Timeline', 'screen': const TimelineScreen()},
      {'icon': Icons.medical_services_outlined, 'label': 'In-House Care', 'screen': const InHouseCareScreen()},
      {'icon': Icons.calendar_today_outlined, 'label': 'Weekly Plan', 'screen': const WeeklyPlanScreen()},
      {'icon': Icons.chat_bubble_outline, 'label': 'Chat', 'screen': const ChatScreen()},
      {'icon': Icons.description_outlined, 'label': 'Medical Reports', 'screen': const MedicalReportsScreen()},
    ];

    return Column(
      children: categories.map((cat) {
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => cat['screen'] as Widget));
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
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
                Icon(cat['icon'] as IconData, color: AppColors.primary, size: 28),
                const SizedBox(width: 16),
                Text(
                  cat['label'] as String,
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services_outlined), label: 'Doctor'),
          BottomNavigationBarItem(icon: Icon(Icons.videocam_outlined), label: 'Video Session'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}