import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movewell/core/theme/colors.dart';
import 'package:movewell/core/widgets/header_background.dart';
import 'package:movewell/core/services/home_visit_service.dart';

class HomeVisitRequestScreen extends StatefulWidget {
  const HomeVisitRequestScreen({super.key});

  @override
  State<HomeVisitRequestScreen> createState() => _HomeVisitRequestScreenState();
}

class _HomeVisitRequestScreenState extends State<HomeVisitRequestScreen> {
  final HomeVisitService _visitService = HomeVisitService();
  String _selectedProvider = 'Nurse';
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;

  final List<Map<String, dynamic>> availableDates = [
    {'day': 'Mon', 'date': '12', 'monthYear': 'May 2026', 'times': ['09:00 AM', '12:00 PM', '03:00 PM', '06:00 PM']},
    {'day': 'Tue', 'date': '13', 'monthYear': 'May 2026', 'times': ['10:00 AM', '02:00 PM', '04:00 PM']},
    {'day': 'Wed', 'date': '14', 'monthYear': 'May 2026', 'times': ['09:00 AM', '11:00 AM', '01:00 PM', '03:00 PM']},
    {'day': 'Thu', 'date': '15', 'monthYear': 'May 2026', 'times': ['10:00 AM', '12:00 PM', '05:00 PM']},
    {'day': 'Fri', 'date': '16', 'monthYear': 'May 2026', 'times': ['09:00 AM', '02:00 PM', '04:00 PM']},
  ];

  Future<void> _submitRequest() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason for the visit')),
      );
      return;
    }
    if (_selectedTimeIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final selectedDate = availableDates[_selectedDateIndex];
      final times = selectedDate['times'] as List<String>;
      final timeStr = times[_selectedTimeIndex];

      await _visitService.requestVisit({
        'providerType': _selectedProvider,
        'date': '${selectedDate['date']} ${selectedDate['monthYear']}',
        'time': timeStr,
        'reason': _reasonController.text.trim(),
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_selectedProvider visit requested successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to request: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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
                            'Request Home Visit',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Schedule a physical therapist or nurse to visit your registered home address.',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 14,
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Select Care Provider',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildProviderCard(
                                  type: 'Doctor',
                                  icon: Icons.medical_services_rounded,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildProviderCard(
                                  type: 'Nurse',
                                  icon: Icons.healing_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Reason for Visit',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _reasonController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Please describe your symptoms...',
                                hintStyle: GoogleFonts.leagueSpartan(color: AppColors.textHint),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(20),
                              ),
                              style: GoogleFonts.leagueSpartan(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Select Date & Time',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(availableDates.length, (index) {
                                final isSelected = index == _selectedDateIndex;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDateIndex = index;
                                      _selectedTimeIndex = -1;
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
                                          availableDates[index]['day'] as String,
                                          style: GoogleFonts.leagueSpartan(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isSelected ? Colors.white70 : AppColors.textHint,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          availableDates[index]['date'] as String,
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
                          const SizedBox(height: 24),
                          Builder(
                            builder: (context) {
                              final times = availableDates[_selectedDateIndex]['times'] as List<String>;
                              if (times.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    child: Text(
                                      'Fully Booked',
                                      style: GoogleFonts.leagueSpartan(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 2.5,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: times.length,
                                itemBuilder: (context, index) {
                                  final isSelected = index == _selectedTimeIndex;
                                  final timeStr = times[index];
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedTimeIndex = index;
                                      });
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primary : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : AppColors.border,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        timeStr,
                                        style: GoogleFonts.leagueSpartan(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? Colors.white : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 48),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_isSubmitting || _selectedTimeIndex == -1) ? null : _submitRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Confirm Request',
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

  Widget _buildProviderCard({required String type, required IconData icon}) {
    final isSelected = _selectedProvider == type;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedProvider = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              type,
              style: GoogleFonts.leagueSpartan(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
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