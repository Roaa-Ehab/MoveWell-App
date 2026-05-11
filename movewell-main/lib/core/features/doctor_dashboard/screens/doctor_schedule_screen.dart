import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movewell/core/theme/colors.dart';
import 'package:movewell/core/services/doctor_service.dart';
import 'package:movewell/core/features/video_session/screens/waiting_room_screen.dart';
import 'package:movewell/core/services/agora_service.dart';
class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  final DoctorService _doctorService = DoctorService();
  List<dynamic> _appointments = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final List<dynamic> appointments = await _doctorService.getSchedule();
      if (mounted) {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _filteredAppointments {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    List<dynamic> filtered = List.from(_appointments);
    
    switch (_selectedFilter) {
      case 'Today':
        filtered = filtered.where((a) {
          try {
            if (a['status'] == 'cancelled') return false;
            final date = DateTime.parse(a['appointmentDate'] ?? '').toLocal();
            final appointmentDay = DateTime(date.year, date.month, date.day);
            return appointmentDay == today;
          } catch (e) {
            return false;
          }
        }).toList();
        break;
      case 'Upcoming':
        filtered = filtered.where((a) {
          try {
            if (a['status'] == 'cancelled' || a['status'] == 'completed') return false;
            final date = DateTime.parse(a['appointmentDate'] ?? '').toLocal();
            return date.isAfter(now);
          } catch (e) {
            return false;
          }
        }).toList();
        break;
      case 'Past':
        filtered = filtered.where((a) {
          try {
            final date = DateTime.parse(a['appointmentDate'] ?? '').toLocal();
            return date.isBefore(now);
          } catch (e) {
            return false;
          }
        }).toList();
        break;
      default:
        break;
    }
    
    filtered.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['appointmentDate'] ?? '').toLocal();
        final dateB = DateTime.parse(b['appointmentDate'] ?? '').toLocal();
        if (_selectedFilter == 'Past') {
          return dateB.compareTo(dateA);
        }
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });
    
    return filtered;
  }

  List<Map<String, dynamic>> get _groupedAppointments {
    if (_selectedFilter != 'All') {
      return [];
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    List<dynamic> todayList = [];
    List<dynamic> upcomingList = [];
    List<dynamic> pastList = [];
    
    for (var appointment in _appointments) {
      try {
        if (appointment['status'] == 'cancelled') continue;
        
        final date = DateTime.parse(appointment['appointmentDate'] ?? '').toLocal();
        final appointmentDay = DateTime(date.year, date.month, date.day);
        
        if (appointmentDay == today) {
          todayList.add(appointment);
        } else if (date.isAfter(now)) {
          upcomingList.add(appointment);
        } else {
          pastList.add(appointment);
        }
      } catch (e) {
        continue;
      }
    }
    
    todayList.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['appointmentDate'] ?? '').toLocal();
        final dateB = DateTime.parse(b['appointmentDate'] ?? '').toLocal();
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });
    upcomingList.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['appointmentDate'] ?? '').toLocal();
        final dateB = DateTime.parse(b['appointmentDate'] ?? '').toLocal();
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });
    pastList.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['appointmentDate'] ?? '').toLocal();
        final dateB = DateTime.parse(b['appointmentDate'] ?? '').toLocal();
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });
    
    List<Map<String, dynamic>> result = [];
    if (todayList.isNotEmpty) {
      result.add({'title': 'Today', 'items': todayList, 'color': AppColors.primary});
    }
    if (upcomingList.isNotEmpty) {
      result.add({'title': 'Upcoming', 'items': upcomingList, 'color': const Color(0xFF4ECDC4)});
    }
    if (pastList.isNotEmpty) {
      result.add({'title': 'Past', 'items': pastList, 'color': AppColors.textMuted});
    }
    return result;
  }

  String formatTime(String dateString) {
    try {
      if (dateString.isEmpty) return 'N/A';
      final DateTime date = DateTime.parse(dateString).toLocal();
      final String minute = date.minute.toString().padLeft(2, '0');
      final String period = date.hour >= 12 ? 'PM' : 'AM';
      final int hour12 = (date.hour % 12 == 0) ? 12 : (date.hour % 12);
      return '$hour12:$minute $period';
    } catch (e) {
      return 'N/A';
    }
  }

  String getFullDate(String dateString) {
    try {
      if (dateString.isEmpty) return 'N/A';
      final DateTime date = DateTime.parse(dateString).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String getPatientName(dynamic appointment) {
    try {
      if (appointment == null) return 'Patient';
      final patientData = appointment['patientId'];
      if (patientData == null) return 'Patient';
      if (patientData is Map) {
        return patientData['name'] ?? 'Patient';
      }
      return 'Patient';
    } catch (e) {
      return 'Patient';
    }
  }

  String getAppointmentStatus(dynamic appointment) {
    try {
      final String status = appointment['status'] ?? 'scheduled';
      final DateTime appointmentDate = DateTime.parse(appointment['appointmentDate'] ?? '').toLocal();
      final now = DateTime.now();
      
      if (status == 'cancelled') {
        return 'cancelled';
      }
      if (status == 'completed') {
        return 'completed';
      }
      if (appointmentDate.isBefore(now)) {
        return 'missed';
      }
      return 'scheduled';
    } catch (e) {
      return 'scheduled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCount = _appointments.where((a) => a['status'] != 'cancelled').length;
    final todayCount = _appointments.where((a) {
      try {
        if (a['status'] == 'cancelled') return false;
        final date = DateTime.parse(a['appointmentDate'] ?? '').toLocal();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final appointmentDay = DateTime(date.year, date.month, date.day);
        return appointmentDay == today;
      } catch (e) {
        return false;
      }
    }).length;
    final upcomingCount = _appointments.where((a) {
      try {
        if (a['status'] == 'cancelled' || a['status'] == 'completed') return false;
        final date = DateTime.parse(a['appointmentDate'] ?? '').toLocal();
        return date.isAfter(DateTime.now());
      } catch (e) {
        return false;
      }
    }).length;
    final pastCount = _appointments.where((a) {
      try {
        final date = DateTime.parse(a['appointmentDate'] ?? '').toLocal();
        return date.isBefore(DateTime.now());
      } catch (e) {
        return false;
      }
    }).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$allCount total appointments',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', allCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Today', todayCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Upcoming', upcomingCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Past', pastCount),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredAppointments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.textHint),
                              const SizedBox(height: 16),
                              Text(
                                'No ${_selectedFilter == 'All' ? '' : _selectedFilter.toLowerCase()} appointments',
                                style: GoogleFonts.leagueSpartan(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your schedule is clear',
                                style: GoogleFonts.leagueSpartan(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _selectedFilter == 'All'
                          ? ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: _groupedAppointments.length,
                              itemBuilder: (context, index) {
                                final group = _groupedAppointments[index];
                                final title = group['title'] as String;
                                final items = group['items'] as List;
                                final color = group['color'] as Color;
                                
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            title,
                                            style: GoogleFonts.leagueSpartan(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: color,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${items.length}',
                                              style: GoogleFonts.leagueSpartan(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: color,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...items.asMap().entries.map((entry) => _buildSessionCard(entry.value, isLast: entry.key == items.length - 1)),
                                    const SizedBox(height: 8),
                                  ],
                                );
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: _filteredAppointments.length,
                              itemBuilder: (BuildContext context, int index) {
                                return _buildSessionCard(_filteredAppointments[index], isLast: index == _filteredAppointments.length - 1);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$label ($count)',
          style: GoogleFonts.leagueSpartan(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(dynamic appointment, {required bool isLast}) {
    final String patientName = getPatientName(appointment);
    final String timeString = formatTime(appointment['appointmentDate'] ?? '');
    final String dateString = getFullDate(appointment['appointmentDate'] ?? '');
    final String appointmentStatus = getAppointmentStatus(appointment);
    
    Color statusColor;
    String statusText;
    bool canJoin = false;
    
    switch (appointmentStatus) {
      case 'completed':
        statusColor = const Color(0xFF4ECDC4);
        statusText = 'Completed';
        canJoin = false;
        break;
      case 'cancelled':
        statusColor = const Color(0xFFFF6B6B);
        statusText = 'Cancelled';
        canJoin = false;
        break;
      case 'missed':
        statusColor = const Color(0xFF9E9E9E);
        statusText = 'Missed';
        canJoin = false;
        break;
      default:
        statusColor = const Color(0xFFFFB347);
        statusText = 'Scheduled';
        canJoin = true;
    }

    String timeHour = '';
    String timePeriod = '';
    if (timeString.contains(' ')) {
      final parts = timeString.split(' ');
      if (parts.length >= 2) {
        timeHour = parts[0];
        timePeriod = parts[1];
      } else {
        timeHour = timeString;
        timePeriod = '';
      }
    } else {
      timeHour = timeString;
      timePeriod = '';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeHour,
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  timePeriod,
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 6),
                if (canJoin)
                  const Icon(Icons.videocam_rounded, size: 16, color: Color(0xFF6C63FF))
                else
                  Icon(Icons.check_circle_rounded, size: 16, color: statusColor),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 30,
                    margin: const EdgeInsets.only(top: 4),
                    color: AppColors.border,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: statusColor, width: 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          patientName,
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateString,
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.videocam_rounded,
                        size: 12,
                        color: const Color(0xFF6C63FF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Video Call',
                        style: GoogleFonts.leagueSpartan(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (canJoin) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        onPressed: () {
                          final channelName = AgoraService.channelForAppointment(appointment['_id'] ?? '');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WaitingRoomScreen(
                                channelName: channelName,
                                remoteName: patientName,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(80, 28),
                        ),
                        child: Text(
                          'Join',
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}