import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:movewell/core/theme/colors.dart';
import 'package:movewell/core/widgets/header_background.dart';
import 'package:movewell/core/features/video_session/screens/waiting_room_screen.dart';
import 'package:movewell/core/services/agora_service.dart';
import 'package:movewell/core/services/doctor_service.dart';
import 'package:movewell/core/services/chat_service.dart';
import 'package:movewell/core/features/chat/screens/doctor_chat_screen.dart';

class DoctorPatientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const DoctorPatientDetailScreen({super.key, required this.patient});

  @override
  State<DoctorPatientDetailScreen> createState() => _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends State<DoctorPatientDetailScreen> {
  final DoctorService _doctorService = DoctorService();
  final ChatService _chatService = ChatService();
  String? _conversationId;
  List<Map<String, dynamic>> _notes = [];
  bool _isLoadingNotes = true;
  bool _isLoadingDocs = true;
  List<Map<String, dynamic>> _documents = [];
  Map<String, dynamic> _homeVisit = {};
  bool _isLoadingVisit = true;

  Map<String, dynamic> get patient => widget.patient;

  @override
  void initState() {
    super.initState();
    _getOrCreateConversation();
    _loadClinicalNotes();
    _loadDocuments();
    _loadHomeVisit();
  }

  Future<void> _loadClinicalNotes() async {
    if (!mounted) return;
    setState(() => _isLoadingNotes = true);
    try {
      final patientId = patient['userId']['_id'];
      final notes = await _doctorService.getClinicalNotes(patientId);
      if (!mounted) return;
      setState(() {
        _notes = notes.map((note) => {
          'id': note['_id'],
          'type': note['type'],
          'content': note['content'],
          'date': _formatDate(note['createdAt']),
          'doctorName': note['doctorId']?['name'] ?? 'Doctor',
        }).toList();
        _isLoadingNotes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingNotes = false);
    }
  }

  Future<void> _loadDocuments() async {
    if (!mounted) return;
    setState(() => _isLoadingDocs = true);
    try {
      final patientId = patient['userId']['_id'];
      final reports = await _doctorService.getPatientReports(patientId);
      if (!mounted) return;
      setState(() {
        _documents = reports.map((doc) => ({
          'id': doc['_id'],
          'title': doc['title'] ?? 'Medical Report',
          'fileUrl': doc['fileUrl'] ?? '',
          'createdAt': doc['createdAt'],
          'type': doc['type'] ?? 'general',
        })).toList();
        _isLoadingDocs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDocs = false);
    }
  }

  void _openDocument(String fileUrl) {
    final fullUrl = 'https://smashup-marshy-kindly.ngrok-free.dev$fileUrl';
    final Uri uri = Uri.parse(fullUrl);
    _launchUrl(uri);
  }

  Future<void> _launchUrl(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    }
  }

  Future<void> _loadHomeVisit() async {
    if (!mounted) return;
    setState(() => _isLoadingVisit = true);
    try {
      final patientId = patient['userId']['_id'];
      final visits = await _doctorService.getHomeVisits(patientId);
      if (!mounted) return;
      if (visits.isNotEmpty) {
        setState(() {
          _homeVisit = visits.first;
          _isLoadingVisit = false;
        });
      } else {
        setState(() => _isLoadingVisit = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingVisit = false);
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final noteDate = DateTime(date.year, date.month, date.day);
      
      if (noteDate == today) {
        return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (noteDate == today.subtract(const Duration(days: 1))) {
        return 'Yesterday';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }

  String _formatDocDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _getOrCreateConversation() async {
    try {
      final patientId = patient['userId']['_id'];
      final conversation = await _chatService.createConversation(patientId);
      if (mounted) {
        setState(() {
          _conversationId = conversation['_id'];
        });
      }
    } catch (e) {
      // Silent error handling
    }
  }

  void _startChat() {
    if (_conversationId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorChatScreen(
            doctorId: patient['userId']['_id'],
            doctorName: patient['userId']['name'],
            conversationId: _conversationId!,
          ),
        ),
      );
    }
  }

  void _startVideoCall() {
    final String channelName = AgoraService.channelForAppointment(DateTime.now().millisecondsSinceEpoch.toString());
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WaitingRoomScreen(
          channelName: channelName,
          remoteName: patient['userId']?['name'] ?? 'Patient',
        ),
      ),
    );
  }

  void _showAddNoteSheet() {
    String selectedType = 'Progress';
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setSheetState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Add Clinical Note',
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'For ${patient['userId']?['name'] ?? 'Patient'}',
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Note Type',
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: ['Progress', 'Assessment', 'Discharge'].map((String type) {
                        final bool isSelected = selectedType == type;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedType = type),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  type,
                                  style: GoogleFonts.leagueSpartan(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      maxLines: 4,
                      style: GoogleFonts.leagueSpartan(fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Write your clinical note...',
                        hintStyle: GoogleFonts.leagueSpartan(fontSize: 14, color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (noteController.text.trim().isEmpty) return;
                          Navigator.pop(ctx);
                          
                          try {
                            final patientId = patient['userId']['_id'];
                            final newNote = await _doctorService.addClinicalNote(
                              patientId,
                              selectedType,
                              noteController.text.trim(),
                            );
                            
                            if (mounted) {
                              setState(() {
                                _notes.insert(0, {
                                  'id': newNote['_id'],
                                  'type': newNote['type'],
                                  'content': newNote['content'],
                                  'date': 'Just now',
                                  'doctorName': 'You',
                                });
                              });
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$selectedType note added.'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add note: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Save Note',
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTreatmentPlanSheet() {
    final TextEditingController diagnosisCtrl = TextEditingController(text: patient['injuryType'] ?? '');
    String selectedStatus = patient['status'] ?? 'active';
    
    String displayStatus = _getDisplayStatus(selectedStatus);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setSheetState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Update Treatment Plan',
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'For ${patient['userId']?['name'] ?? 'Patient'}',
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSheetField('Diagnosis', diagnosisCtrl),
                    const SizedBox(height: 14),
                    Text(
                      'Status',
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusOption(
                            'Active',
                            displayStatus,
                            () => setSheetState(() {
                              displayStatus = 'Active';
                              selectedStatus = 'active';
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatusOption(
                            'Needs Attention',
                            displayStatus,
                            () => setSheetState(() {
                              displayStatus = 'Needs Attention';
                              selectedStatus = 'needs_attention';
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatusOption(
                            'Discharged',
                            displayStatus,
                            () => setSheetState(() {
                              displayStatus = 'Discharged';
                              selectedStatus = 'discharged';
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          try {
                            await _doctorService.updatePatientStatus(
                              patient['userId']['_id'],
                              selectedStatus,
                              diagnosisCtrl.text.trim(),
                            );
                            if (mounted) {
                              setState(() {
                                patient['status'] = selectedStatus;
                                patient['injuryType'] = diagnosisCtrl.text.trim();
                              });
                              
                              Navigator.pop(context, {
                                'status': selectedStatus,
                                'injuryType': diagnosisCtrl.text.trim(),
                                'patientId': patient['userId']['_id'],
                                'patientName': patient['userId']?['name'],
                              });
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Treatment plan updated.')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getDisplayStatus(String status) {
    if (status == 'needs_attention') {
      return 'Needs Attention';
    }
    if (status == 'discharged') {
      return 'Discharged';
    }
    return 'Active';
  }

  Widget _buildStatusOption(String label, String selectedStatus, VoidCallback onTap) {
    final isSelected = selectedStatus == label;
    String displayLabel = label;
    if (label == 'Needs Attention') {
      displayLabel = 'Attention';
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            displayLabel,
            style: GoogleFonts.leagueSpartan(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetField(String label, TextEditingController ctrl, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.leagueSpartan(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.leagueSpartan(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderTopArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          const Spacer(),
          Text(
            'Patient Details',
            style: GoogleFonts.leagueSpartan(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPatientHeader(String patientName, String patientAge, String patientDiagnosis, String status, Color statusBg, Color statusText) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.surface,
          child: Text(
            patientName.isNotEmpty ? patientName[0] : 'P',
            style: GoogleFonts.leagueSpartan(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      patientName,
                      style: GoogleFonts.leagueSpartan(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      status,
                      style: GoogleFonts.leagueSpartan(fontSize: 11, fontWeight: FontWeight.w600, color: statusText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$patientAge years old',
                style: GoogleFonts.leagueSpartan(fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                patientDiagnosis,
                style: GoogleFonts.leagueSpartan(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdherenceCard() {
    double adherence = 0.75;
    int pct = (adherence * 100).toInt();
    Color barColor = const Color(0xFF4ECDC4);
    String statusLabel = 'Good';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Exercise Adherence', style: GoogleFonts.leagueSpartan(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: barColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Text(statusLabel, style: GoogleFonts.leagueSpartan(fontSize: 12, fontWeight: FontWeight.w600, color: barColor)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: adherence,
                    minHeight: 10,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$pct%', style: GoogleFonts.leagueSpartan(fontSize: 18, fontWeight: FontWeight.bold, color: barColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSummaryCard() {
    final String patientPhone = patient['userId']?['phone'] ?? 'N/A';
    
    String emergencyContact = patient['emergencyContact'] ?? 'N/A';
    if (emergencyContact.contains(':')) {
      final parts = emergencyContact.split(':');
      emergencyContact = parts[0].trim();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health Summary', style: GoogleFonts.leagueSpartan(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInfoItem(Icons.water_drop_outlined, 'Blood', patient['bloodType'] ?? 'N/A')),
              Expanded(child: _buildInfoItem(Icons.height_rounded, 'Height', patient['height']?.toString() ?? 'N/A')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInfoItem(Icons.monitor_weight_outlined, 'Weight', patient['weight']?.toString() ?? 'N/A')),
              Expanded(child: _buildInfoItem(Icons.phone_outlined, 'Phone', patientPhone)),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(Icons.emergency_outlined, 'Emergency', emergencyContact),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInfoItem(Icons.event_outlined, 'Last Visit', patient['lastVisit'] ?? 'N/A')),
              Expanded(child: _buildInfoItem(Icons.event_available_outlined, 'Next Appt.', patient['nextAppointment'] ?? 'N/A')),
            ],
          ),
          if (_isLoadingVisit)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  SizedBox(width: 32),
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Loading home visit...'),
                ],
              ),
            )
          else if (_homeVisit.isNotEmpty && _homeVisit['date'] != null) ...[
            const SizedBox(height: 12),
            _buildInfoItem(Icons.home_rounded, 'Home Visit', _homeVisit['date']),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.leagueSpartan(fontSize: 11, color: AppColors.textHint)),
                Text(value, style: GoogleFonts.leagueSpartan(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionProgress() {
    final completed = patient['completedSessions'] ?? 0;
    final total = patient['totalSessions'] ?? 0;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Treatment Progress',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toInt()}% Complete',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4ECDC4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressRow('Completed Sessions', '$completed / $total', AppColors.primary),
                    const SizedBox(height: 8),
                    _buildProgressRow('Remaining', '${total - completed} sessions', AppColors.textMuted),
                    const SizedBox(height: 8),
                    _buildProgressRow('Overall Progress', '${(progress * 100).toInt()}%', const Color(0xFF4ECDC4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          FutureBuilder(
            future: _doctorService.getPatientTrackingSummary(patient['userId']['_id']),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final data = snapshot.data!;
              final totalEntries = data['totalEntries'] ?? 0;
              final avgProgress = (data['averageProgress'] ?? 0).toDouble();
              final improvement = data['progressImprovement'] ?? 0;

              if (totalEntries == 0) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart, size: 20, color: AppColors.textHint),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No tracking data available yet',
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTrackingItem(
                          'Avg. Progress',
                          '${avgProgress.toInt()}%',
                          const Color(0xFF4ECDC4),
                        ),
                      ),
                      Expanded(
                        child: _buildTrackingItem(
                          'Entries',
                          totalEntries.toString(),
                          AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: _buildTrackingItem(
                          'Improvement',
                          '${improvement > 0 ? '+' : ''}$improvement%',
                          improvement >= 0 ? const Color(0xFF4ECDC4) : AppColors.sos,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.leagueSpartan(fontSize: 13, color: AppColors.textMuted)),
        Text(value, style: GoogleFonts.leagueSpartan(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _buildTrackingItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.leagueSpartan(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.leagueSpartan(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalNotes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Clinical Notes', style: GoogleFonts.leagueSpartan(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              GestureDetector(
                onTap: _showAddNoteSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Add', style: GoogleFonts.leagueSpartan(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingNotes)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_notes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Icon(Icons.note_alt_outlined, size: 36, color: AppColors.textHint),
                  const SizedBox(height: 8),
                  Text('No notes yet', style: GoogleFonts.leagueSpartan(fontSize: 14, color: AppColors.textMuted)),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _notes.length,
              itemBuilder: (context, index) => _buildNoteCard(_notes[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    Color typeColor;
    IconData typeIcon;
    switch (note['type']) {
      case 'Assessment':
        typeColor = const Color(0xFFFFB347);
        typeIcon = Icons.assignment_outlined;
        break;
      case 'Discharge':
        typeColor = const Color(0xFF4ECDC4);
        typeIcon = Icons.exit_to_app_rounded;
        break;
      default:
        typeColor = AppColors.primary;
        typeIcon = Icons.trending_up_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: typeColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(typeIcon, size: 16, color: typeColor),
              const SizedBox(width: 6),
              Text(note['type'] ?? 'Progress', style: GoogleFonts.leagueSpartan(fontSize: 12, fontWeight: FontWeight.w600, color: typeColor)),
              const Spacer(),
              Text(note['date'] ?? 'Unknown', style: GoogleFonts.leagueSpartan(fontSize: 12, color: AppColors.textHint)),
            ],
          ),
          const SizedBox(height: 8),
          Text(note['content'] ?? '', style: GoogleFonts.leagueSpartan(fontSize: 13, height: 1.5, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('— Dr. ${note['doctorName']}', style: GoogleFonts.leagueSpartan(fontSize: 11, color: AppColors.textHint, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildPatientDocuments() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Patient Documents', style: GoogleFonts.leagueSpartan(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                child: Text('${_documents.length} file${_documents.length == 1 ? '' : 's'}', style: GoogleFonts.leagueSpartan(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingDocs)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_documents.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Icon(Icons.folder_open_rounded, size: 36, color: AppColors.textHint),
                  const SizedBox(height: 8),
                  Text('No documents uploaded yet', style: GoogleFonts.leagueSpartan(fontSize: 14, color: AppColors.textMuted)),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _documents.length,
              itemBuilder: (context, index) => _buildDocumentCard(_documents[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final dateStr = _formatDocDate(doc['createdAt'] ?? '');
    final String fileUrl = doc['fileUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['title'] ?? 'Medical Report',
                  style: GoogleFonts.leagueSpartan(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(dateStr, style: GoogleFonts.leagueSpartan(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _openDocument(fileUrl),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.visibility_outlined, color: AppColors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionBtn(
                icon: Icons.videocam_rounded,
                label: 'Video Session',
                color: const Color(0xFF6C63FF),
                onTap: _startVideoCall,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionBtn(
                icon: Icons.chat_bubble_outline,
                label: 'Message',
                color: const Color(0xFF4ECDC4),
                onTap: _startChat,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _buildActionBtn(
            icon: Icons.edit_note_rounded,
            label: 'Update Treatment Plan',
            color: AppColors.primary,
            onTap: _showTreatmentPlanSheet,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.leagueSpartan(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientName = patient['userId']?['name'] ?? 'Patient';
    final patientAge = patient['age']?.toString() ?? 'N/A';
    final patientDiagnosis = patient['injuryType'] ?? 'No diagnosis';
    final rawStatus = patient['status'] ?? 'active';
    final status = _getDisplayStatus(rawStatus);

    Color statusBg;
    Color statusText;
    if (rawStatus == 'needs_attention') {
      statusBg = const Color(0xFFFFB347).withValues(alpha: 0.12);
      statusText = const Color(0xFFFFB347);
    } else if (rawStatus == 'discharged') {
      statusBg = AppColors.textMuted.withValues(alpha: 0.12);
      statusText = AppColors.textMuted;
    } else {
      statusBg = const Color(0xFF4ECDC4).withValues(alpha: 0.12);
      statusText = const Color(0xFF4ECDC4);
    }

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPatientHeader(patientName, patientAge, patientDiagnosis, status, statusBg, statusText),
                          const SizedBox(height: 24),
                          _buildAdherenceCard(),
                          const SizedBox(height: 20),
                          _buildHealthSummaryCard(),
                          const SizedBox(height: 20),
                          _buildSessionProgress(),
                          const SizedBox(height: 20),
                          _buildClinicalNotes(),
                          const SizedBox(height: 20),
                          _buildPatientDocuments(),
                          const SizedBox(height: 20),
                          _buildActionButtons(context),
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
}