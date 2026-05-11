import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movewell/core/theme/colors.dart';
import 'package:movewell/core/widgets/header_background.dart';
import 'package:movewell/core/services/appointment_service.dart';
import 'package:movewell/core/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  int _selectedDateIndex = 0;
  bool _isBooking = false;
  String? _selectedDoctorId;
  String? _selectedDoctorName;
  List<dynamic> _doctors = [];
  List<Map<String, dynamic>> _availableDates = [];
  bool _isLoadingDates = true;
  String? _currentUserId;
  TimeOfDay? _selectedTime;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = authProvider.userId;
    _loadDoctors();
    _generateAvailableDates();
  }

  void _generateAvailableDates() {
    final now = DateTime.now();
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    _availableDates = [];
    for (int i = 0; i < 14; i++) {
      final date = now.add(Duration(days: i));
      final monthYear = '${months[date.month - 1]} ${date.year}';
      _availableDates.add({
        'day': weekDays[date.weekday - 1],
        'date': date.day.toString(),
        'monthYear': monthYear,
        'fullDate': date,
      });
    }
    setState(() {
      _isLoadingDates = false;
      _selectedDate = _availableDates[0]['fullDate'];
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await _appointmentService.getDoctors();
      final availableDoctors = doctors.where((d) => d['_id'] != _currentUserId).toList();
      if (mounted) {
        setState(() {
          _doctors = availableDoctors;
          if (_doctors.isNotEmpty) {
            _selectedDoctorId = _doctors[0]['_id'];
            _selectedDoctorName = _doctors[0]['name'];
          }
        });
      }
    } catch (e) {
      // Silent error handling
    }
  }

  void _selectDoctor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select a Doctor',
                style: GoogleFonts.leagueSpartan(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _doctors[index];
                    final doctorName = doctor['name'] ?? 'Doctor';
                    final doctorEmail = doctor['email'] ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.surface,
                        child: Text(
                          doctorName.isNotEmpty ? doctorName[0] : 'D',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: AppColors.primary
                          ),
                        ),
                      ),
                      title: Text(
                        doctorName,
                        style: GoogleFonts.leagueSpartan(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        doctorEmail,
                        style: GoogleFonts.leagueSpartan(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                      onTap: () {
                        setState(() {
                          _selectedDoctorId = doctor['_id'];
                          _selectedDoctorName = doctorName;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _bookAppointment() async {
    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a doctor')),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      // Create DateTime in LOCAL timezone
      final localDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      
      // Convert to UTC for storage in backend
      final utcDateTime = localDateTime.toUtc();
      
      await _appointmentService.createAppointment({
        'doctorId': _selectedDoctorId,
        'appointmentDate': utcDateTime.toIso8601String(),
        'duration': 30,
        'type': 'video',
        'notes': '',
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment Booked Successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const HeaderBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeaderTopArea(context),
                const SizedBox(height: 20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book an Appointment',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select the doctor, date, and time for your appointment.',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          Text(
                            'Select Doctor',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _selectDoctor,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline, color: AppColors.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedDoctorName ?? 'Select a doctor',
                                      style: GoogleFonts.leagueSpartan(
                                        fontSize: 16,
                                        color: _selectedDoctorName != null ? AppColors.textPrimary : AppColors.textHint,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          Text(
                            'Select Date',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          if (_isLoadingDates)
                            const Center(child: CircularProgressIndicator())
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(_availableDates.length, (index) {
                                  final isSelected = index == _selectedDateIndex;
                                  final dateData = _availableDates[index];
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedDateIndex = index;
                                        _selectedDate = dateData['fullDate'];
                                      });
                                    },
                                    child: Container(
                                      width: 70,
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primary : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : AppColors.border,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            dateData['day'] as String,
                                            style: GoogleFonts.leagueSpartan(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: isSelected ? Colors.white70 : AppColors.textHint,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            dateData['date'] as String,
                                            style: GoogleFonts.leagueSpartan(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.white : AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          
                          const SizedBox(height: 32),
                          
                          Text(
                            'Select Time',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          GestureDetector(
                            onTap: _selectTime,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, color: AppColors.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedTime != null 
                                          ? formatTime(_selectedTime!) 
                                          : 'Select time',
                                      style: GoogleFonts.leagueSpartan(
                                        fontSize: 16,
                                        color: _selectedTime != null ? AppColors.textPrimary : AppColors.textHint,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 48),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_isBooking || _selectedTime == null || _selectedDoctorId == null) ? null : _bookAppointment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isBooking
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Confirm Booking',
                                      style: GoogleFonts.leagueSpartan(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
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

  Widget _buildHeaderTopArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}