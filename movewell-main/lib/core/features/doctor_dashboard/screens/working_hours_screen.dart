import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movewell/core/theme/colors.dart';

class WorkingHoursScreen extends StatefulWidget {
  const WorkingHoursScreen({super.key});

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  bool mondayEnabled = true;
  bool tuesdayEnabled = true;
  bool wednesdayEnabled = true;
  bool thursdayEnabled = true;
  bool fridayEnabled = true;
  bool saturdayEnabled = false;
  bool sundayEnabled = false;

  TimeOfDay mondayStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay mondayEnd = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay tuesdayStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay tuesdayEnd = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay wednesdayStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay wednesdayEnd = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay thursdayStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay thursdayEnd = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay fridayStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay fridayEnd = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay saturdayStart = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay saturdayEnd = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay sundayStart = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay sundayEnd = const TimeOfDay(hour: 14, minute: 0);

  Future<void> _selectTime(BuildContext context, bool isStart, String day, bool isEnabled) async {
    if (!isEnabled) return;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _getStartTime(day) : _getEndTime(day),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _setStartTime(day, picked);
        } else {
          _setEndTime(day, picked);
        }
      });
    }
  }

  TimeOfDay _getStartTime(String day) {
    switch (day) {
      case 'Monday': return mondayStart;
      case 'Tuesday': return tuesdayStart;
      case 'Wednesday': return wednesdayStart;
      case 'Thursday': return thursdayStart;
      case 'Friday': return fridayStart;
      case 'Saturday': return saturdayStart;
      default: return sundayStart;
    }
  }

  TimeOfDay _getEndTime(String day) {
    switch (day) {
      case 'Monday': return mondayEnd;
      case 'Tuesday': return tuesdayEnd;
      case 'Wednesday': return wednesdayEnd;
      case 'Thursday': return thursdayEnd;
      case 'Friday': return fridayEnd;
      case 'Saturday': return saturdayEnd;
      default: return sundayEnd;
    }
  }

  void _setStartTime(String day, TimeOfDay time) {
    switch (day) {
      case 'Monday': mondayStart = time; break;
      case 'Tuesday': tuesdayStart = time; break;
      case 'Wednesday': wednesdayStart = time; break;
      case 'Thursday': thursdayStart = time; break;
      case 'Friday': fridayStart = time; break;
      case 'Saturday': saturdayStart = time; break;
      default: sundayStart = time;
    }
  }

  void _setEndTime(String day, TimeOfDay time) {
    switch (day) {
      case 'Monday': mondayEnd = time; break;
      case 'Tuesday': tuesdayEnd = time; break;
      case 'Wednesday': wednesdayEnd = time; break;
      case 'Thursday': thursdayEnd = time; break;
      case 'Friday': fridayEnd = time; break;
      case 'Saturday': saturdayEnd = time; break;
      default: sundayEnd = time;
    }
  }

  String formatTime(TimeOfDay time) {
    return '${time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Working hours saved successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Working Hours',
          style: GoogleFonts.leagueSpartan(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDayRow('Monday', mondayEnabled, (val) {
              setState(() => mondayEnabled = val);
            }, () => _selectTime(context, true, 'Monday', mondayEnabled), () => _selectTime(context, false, 'Monday', mondayEnabled), formatTime(mondayStart), formatTime(mondayEnd)),
            const SizedBox(height: 12),
            _buildDayRow('Tuesday', tuesdayEnabled, (val) {
              setState(() => tuesdayEnabled = val);
            }, () => _selectTime(context, true, 'Tuesday', tuesdayEnabled), () => _selectTime(context, false, 'Tuesday', tuesdayEnabled), formatTime(tuesdayStart), formatTime(tuesdayEnd)),
            const SizedBox(height: 12),
            _buildDayRow('Wednesday', wednesdayEnabled, (val) {
              setState(() => wednesdayEnabled = val);
            }, () => _selectTime(context, true, 'Wednesday', wednesdayEnabled), () => _selectTime(context, false, 'Wednesday', wednesdayEnabled), formatTime(wednesdayStart), formatTime(wednesdayEnd)),
            const SizedBox(height: 12),
            _buildDayRow('Thursday', thursdayEnabled, (val) {
              setState(() => thursdayEnabled = val);
            }, () => _selectTime(context, true, 'Thursday', thursdayEnabled), () => _selectTime(context, false, 'Thursday', thursdayEnabled), formatTime(thursdayStart), formatTime(thursdayEnd)),
            const SizedBox(height: 12),
            _buildDayRow('Friday', fridayEnabled, (val) {
              setState(() => fridayEnabled = val);
            }, () => _selectTime(context, true, 'Friday', fridayEnabled), () => _selectTime(context, false, 'Friday', fridayEnabled), formatTime(fridayStart), formatTime(fridayEnd)),
            const SizedBox(height: 12),
            _buildDayRow('Saturday', saturdayEnabled, (val) {
              setState(() => saturdayEnabled = val);
            }, () => _selectTime(context, true, 'Saturday', saturdayEnabled), () => _selectTime(context, false, 'Saturday', saturdayEnabled), formatTime(saturdayStart), formatTime(saturdayEnd)),
            const SizedBox(height: 12),
            _buildDayRow('Sunday', sundayEnabled, (val) {
              setState(() => sundayEnabled = val);
            }, () => _selectTime(context, true, 'Sunday', sundayEnabled), () => _selectTime(context, false, 'Sunday', sundayEnabled), formatTime(sundayStart), formatTime(sundayEnd)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Save Settings',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayRow(String day, bool enabled, Function(bool) onToggle, VoidCallback onStartTap, VoidCallback onEndTap, String startTime, String endTime) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: GoogleFonts.leagueSpartan(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onStartTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Start',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            startTime,
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onEndTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'End',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            endTime,
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}