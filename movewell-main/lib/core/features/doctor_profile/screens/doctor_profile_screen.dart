import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movewell/core/theme/colors.dart';
import 'package:movewell/core/features/chat/screens/doctor_chat_screen.dart';
import 'package:movewell/core/services/doctor_chat_service.dart';
import 'package:movewell/core/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final DoctorChatService _doctorService = DoctorChatService();
  List<dynamic> _doctors = [];
  bool _isLoading = true;
  String? _currentUserId;
  String _selectedDoctorName = '';
  String _selectedDoctorId = '';

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = authProvider.userId;
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final doctors = await _doctorService.getAllDoctors();
      if (!mounted) return;
      final filteredDoctors = doctors.where((d) => d['_id'] != _currentUserId).toList();
      setState(() {
        _doctors = filteredDoctors;
        _isLoading = false;
        if (_doctors.isNotEmpty) {
          _selectedDoctorName = _doctors[0]['name'] ?? '';
          _selectedDoctorId = _doctors[0]['_id'] ?? '';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showDoctorSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
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
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      title: Text(
                        doctorName,
                        style: GoogleFonts.leagueSpartan(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        doctorEmail,
                        style: GoogleFonts.leagueSpartan(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                      onTap: () {
                        setState(() {
                          _selectedDoctorName = doctorName;
                          _selectedDoctorId = doctor['_id'] ?? '';
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

  void _startChat() async {
    if (_selectedDoctorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a doctor first')),
      );
      return;
    }

    try {
      final conversation = await _doctorService.createConversation(_selectedDoctorId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorChatScreen(
              doctorId: _selectedDoctorId,
              doctorName: _selectedDoctorName,
              conversationId: conversation['_id'] ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  String getDoctorLastName() {
    if (_selectedDoctorName.isEmpty) return 'Doctor';
    final parts = _selectedDoctorName.split(' ');
    if (parts.length > 1) {
      return parts.last;
    }
    return _selectedDoctorName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            _buildProfileContent(),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: Center(
              child: Text(
                _selectedDoctorName.isNotEmpty ? _selectedDoctorName[0] : '?',
                style: GoogleFonts.leagueSpartan(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your Doctor',
            style: GoogleFonts.leagueSpartan(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedDoctorName.isNotEmpty ? _selectedDoctorName : 'Select a Doctor',
            style: GoogleFonts.leagueSpartan(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lead Physiotherapist',
            style: GoogleFonts.leagueSpartan(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'About Your Doctor',
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_doctors.isNotEmpty)
                      GestureDetector(
                        onTap: _showDoctorSelectionSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.swap_horiz, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Change',
                                style: GoogleFonts.leagueSpartan(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _selectedDoctorName.isNotEmpty
                      ? 'With over 10 years of clinical experience in sports rehabilitation and orthopedic physical therapy, Dr. ${getDoctorLastName()} specializes in helping patients recover optimally using tailored, progressive treatment plans.'
                      : 'Select a doctor from the list below to view their profile and start a conversation.',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '4.9 (124+ Reviews)',
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _doctors.isEmpty ? null : _startChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                _doctors.isEmpty ? 'No doctors available' : 'Chat directly',
                style: GoogleFonts.leagueSpartan(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}