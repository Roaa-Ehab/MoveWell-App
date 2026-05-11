import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:movewell/core/theme/colors.dart';
import 'package:movewell/core/widgets/header_background.dart';
import 'package:movewell/core/features/auth/providers/auth_provider.dart';
import 'package:movewell/core/services/doctor_service.dart';
import 'package:movewell/core/features/doctor_dashboard/screens/doctor_patients_screen.dart';
import 'package:movewell/core/features/doctor_dashboard/screens/doctor_schedule_screen.dart';
import 'package:movewell/core/features/doctor_dashboard/screens/doctor_profile_settings_screen.dart';
import 'package:movewell/core/features/doctor_dashboard/screens/doctor_patient_detail_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _currentIndex = 0;
  final DoctorService _doctorService = DoctorService();
  List<dynamic> _appointments = [];
  bool _isLoading = true;
  String _doctorName = '';
  int _totalPatients = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _doctorName = authProvider.userName;
      final patients = await _doctorService.getPatients();
      final appointments = await _doctorService.getSchedule();
      
      setState(() {
        _appointments = appointments;
        _totalPatients = patients.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToPatientDetail(String patientId) async {
    try {
      final patient = await _doctorService.getPatientById(patientId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorPatientDetailScreen(patient: patient),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load patient details: $e')),
        );
      }
    }
  }

  String formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      return '$hour12:$minute $period';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(context),
          const DoctorPatientsScreen(),
          const DoctorScheduleScreen(),
          const DoctorProfileSettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    final todayAppointments = _appointments.where((a) {
      try {
        final date = DateTime.parse(a['appointmentDate']).toLocal();
        return date.isAfter(today) && date.isBefore(todayEnd) && a['status'] != 'cancelled';
      } catch (e) {
        return false;
      }
    }).toList()
    ..sort((a, b) {
      final dateA = DateTime.parse(a['appointmentDate']).toLocal();
      final dateB = DateTime.parse(b['appointmentDate']).toLocal();
      return dateA.compareTo(dateB);
    });

    return Stack(
      children: [
        const HeaderBackground(),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeaderTopArea(),
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
                          _buildGreeting(),
                          const SizedBox(height: 24),
                          _buildStatsRow(),
                          const SizedBox(height: 28),
                          _buildSectionTitle("Today's Agenda"),
                          const SizedBox(height: 16),
                          if (todayAppointments.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.check_circle_outline, color: AppColors.primary, size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No appointments today',
                                    style: GoogleFonts.leagueSpartan(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...todayAppointments.map((appointment) => _buildAgendaCard(appointment)),
                        ],
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
    );
  }

  Widget _buildHeaderTopArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
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

  Widget _buildGreeting() {
    final firstName = _doctorName.isNotEmpty ? _doctorName.split(' ')[0] : 'Doctor';
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

  Widget _buildStatsRow() {
    final todayCount = _appointments.where((a) {
      final now = DateTime.now();
      final date = DateTime.parse(a['appointmentDate']).toLocal();
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }).length;
    final upcomingCount = _appointments.where((a) {
      final date = DateTime.parse(a['appointmentDate']).toLocal();
      return date.isAfter(DateTime.now()) && a['status'] != 'cancelled';
    }).length;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.people_outline,
            value: '$_totalPatients',
            label: 'Patients',
            color: const Color(0xFF4ECDC4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.today_outlined,
            value: '$todayCount',
            label: 'Today',
            color: const Color(0xFFFFB347),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_month_outlined,
            value: '$upcomingCount',
            label: 'Upcoming',
            color: const Color(0xFF6C63FF),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.leagueSpartan(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.leagueSpartan(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaCard(dynamic appointment) {
    final patient = appointment['patientId'];
    final patientName = patient?['name'] ?? 'Patient';
    final patientId = patient?['_id'];
    final timeStr = formatTime(appointment['appointmentDate']);
    final sessionType = appointment['type'] == 'video' ? 'Video Session' : 'In-Person';
    
    final timeParts = timeStr.split(' ');
    final timeHour = timeParts.isNotEmpty ? timeParts[0] : '';
    final timePeriod = timeParts.length > 1 ? timeParts[1] : '';

    Color typeColor;
    IconData typeIcon;
    if (sessionType == 'Video Session') {
      typeColor = const Color(0xFF6C63FF);
      typeIcon = Icons.videocam_rounded;
    } else {
      typeColor = const Color(0xFF4ECDC4);
      typeIcon = Icons.person_rounded;
    }

    return GestureDetector(
      onTap: () {
        if (patientId != null) {
          _navigateToPatientDetail(patientId);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: typeColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  Text(
                    timeHour,
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    timePeriod,
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, size: 14, color: typeColor),
                        const SizedBox(width: 4),
                        Text(
                          sessionType,
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: typeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.leagueSpartan(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildBottomNav() {
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
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}