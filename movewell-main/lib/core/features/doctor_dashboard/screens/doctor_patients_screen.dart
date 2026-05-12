import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movewell/core/theme/colors.dart';
import 'package:movewell/core/services/doctor_service.dart';
import 'package:movewell/core/features/doctor_dashboard/screens/doctor_patient_detail_screen.dart';
import 'package:movewell/core/features/doctor_dashboard/screens/doctor_qr_scanner_screen.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  final DoctorService _doctorService = DoctorService();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _patients = [];
  bool _isLoading = true;
  final Map<String, double> _adherenceMap = {};

  static const List<String> _filters = ['All', 'Active', 'Needs Attention', 'Discharged'];

  String _getDisplayStatus(String status) {
    if (status == 'needs_attention') {
      return 'Needs Attention';
    }
    if (status == 'discharged') {
      return 'Discharged';
    }
    return 'Active';
  }

  String _getFilterStatus(String filter) {
    if (filter == 'Needs Attention') {
      return 'needs_attention';
    }
    if (filter == 'Discharged') {
      return 'discharged';
    }
    if (filter == 'Active') {
      return 'active';
    }
    return filter;
  }

  List<dynamic> get _filteredPatients {
    List<dynamic> list = _patients.toList();

    if (_searchQuery.isNotEmpty) {
      final String q = _searchQuery.toLowerCase();
      list = list.where((dynamic p) {
        final String name = p['userId']?['name']?.toLowerCase() ?? '';
        final String diagnosis = p['injuryType']?.toLowerCase() ?? '';
        return name.contains(q) || diagnosis.contains(q);
      }).toList();
    }

    if (_selectedFilter != 'All') {
      final String filterStatus = _getFilterStatus(_selectedFilter);
      list = list.where((dynamic p) {
        String status = p['status'] ?? 'active';
        return status == filterStatus;
      }).toList();
    }

    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final List<dynamic> patients = await _doctorService.getPatients();
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _isLoading = false;
      });
      _loadAdherenceForAllPatients();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAdherenceForAllPatients() async {
    for (var patient in _patients) {
      final patientId = patient['userId']['_id'];
      final adherence = await _doctorService.getPatientAdherence(patientId);
      if (mounted) {
        setState(() {
          _adherenceMap[patientId] = adherence;
        });
      }
    }
  }

  Future<void> _navigateToPatientDetail(dynamic patient) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorPatientDetailScreen(patient: patient),
      ),
    );
    
    if (result != null && mounted) {
      _loadPatients();
    }
  }

  Color _getAdherenceColor(double adherence) {
    if (adherence >= 0.8) {
      return const Color(0xFF4ECDC4);
    } else if (adherence >= 0.6) {
      return const Color(0xFFFFB347);
    } else {
      return const Color(0xFFFF6B6B);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int activeCount = _patients.where((p) => p['status'] == 'active').length;
    final int needsAttentionCount = _patients.where((p) => p['status'] == 'needs_attention').length;
    final int dischargedCount = _patients.where((p) => p['status'] == 'discharged').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPatients,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Patients',
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.primary),
                          onPressed: _loadPatients,
                        ),
                        GestureDetector(
                          onTap: () async {
                            final bool? result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DoctorQrScannerScreen()),
                            );
                            if (result == true && mounted) {
                              _loadPatients();
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '${_patients.length} total patients',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (String value) => setState(() => _searchQuery = value),
                    style: GoogleFonts.leagueSpartan(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search patients...',
                      hintStyle: GoogleFonts.leagueSpartan(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final String filter = _filters[index];
                    final bool isSelected = filter == _selectedFilter;
                    int count = 0;
                    if (filter == 'All') {
                      count = _patients.length;
                    } else if (filter == 'Active') {
                      count = activeCount;
                    } else if (filter == 'Needs Attention') {
                      count = needsAttentionCount;
                    } else if (filter == 'Discharged') {
                      count = dischargedCount;
                    }
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected ? null : Border.all(color: AppColors.border),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          '$filter ($count)',
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredPatients.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 56, color: AppColors.textHint),
                                const SizedBox(height: 12),
                                Text(
                                  'No patients found',
                                  style: GoogleFonts.leagueSpartan(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Scan a patient QR code to add them',
                                  style: GoogleFonts.leagueSpartan(
                                    fontSize: 12,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _filteredPatients.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (BuildContext context, int index) {
                              return _buildPatientCard(_filteredPatients[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(dynamic patient) {
    final String patientName = patient['userId']?['name'] ?? 'Unknown Patient';
    final String patientDiagnosis = patient['injuryType'] ?? 'No diagnosis';
    final String rawStatus = patient['status'] ?? 'active';
    final String patientStatus = _getDisplayStatus(rawStatus);
    final String patientId = patient['userId']['_id'];
    
    double adherence = _adherenceMap[patientId] ?? 0.0;
    int pct = (adherence * 100).toInt();

    Color statusColor;
    if (rawStatus == 'needs_attention') {
      statusColor = const Color(0xFFFFB347);
    } else if (rawStatus == 'discharged') {
      statusColor = AppColors.textMuted;
    } else {
      statusColor = const Color(0xFF4ECDC4);
    }

    Color adherenceColor = _getAdherenceColor(adherence);

    Color statusBgColor = statusColor.withValues(alpha: 0.12);
    Color statusTextColor = statusColor;

    return GestureDetector(
      onTap: () => _navigateToPatientDetail(patient),
      child: Container(
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
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      value: adherence,
                      strokeWidth: 3,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(adherenceColor),
                    ),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surface,
                    child: Text(
                      patientName.isNotEmpty ? patientName[0] : '?',
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
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
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          patientStatus,
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patientDiagnosis,
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        'Last visit: N/A',
                        style: GoogleFonts.leagueSpartan(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$pct%',
                        style: GoogleFonts.leagueSpartan(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: adherenceColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}