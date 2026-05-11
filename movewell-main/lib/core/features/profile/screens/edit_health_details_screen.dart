import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movewell/core/theme/colors.dart';
import 'package:movewell/core/widgets/header_background.dart';
import 'package:movewell/core/services/patient_service.dart';

class EditHealthDetailsScreen extends StatefulWidget {
  const EditHealthDetailsScreen({super.key});

  @override
  State<EditHealthDetailsScreen> createState() => _EditHealthDetailsScreenState();
}

class _EditHealthDetailsScreenState extends State<EditHealthDetailsScreen> {
  final PatientService _patientService = PatientService();
  bool _isLoading = true;
  bool _isSaving = false;
  
  String _selectedBloodType = 'A+';
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _diagnosisController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _diagnosisController = TextEditingController();
    _emergencyNameController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
    _ageController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _patientService.getProfile();
      setState(() {
        if (data['bloodType'] != null && data['bloodType'].isNotEmpty) {
          _selectedBloodType = data['bloodType'];
        }
        _heightController.text = data['height'] != null ? data['height'].toString() : '';
        _weightController.text = data['weight'] != null ? data['weight'].toString() : '';
        _diagnosisController.text = data['injuryType'] ?? '';
        
        final emergency = data['emergencyContact'] ?? '';
        if (emergency.contains(':')) {
          final parts = emergency.split(':');
          _emergencyNameController.text = parts[0].trim();
          _emergencyPhoneController.text = parts.length > 1 ? parts[1].trim() : '';
        } else {
          _emergencyNameController.text = emergency;
          _emergencyPhoneController.text = '';
        }
        
        _ageController.text = data['age'] != null ? data['age'].toString() : '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    final height = _heightController.text.trim();
    final weight = _weightController.text.trim();
    final diagnosis = _diagnosisController.text.trim();
    final emergencyName = _emergencyNameController.text.trim();
    final emergencyPhone = _emergencyPhoneController.text.trim();
    final age = _ageController.text.trim();

    String emergencyContact = '';
    if (emergencyName.isNotEmpty) {
      emergencyContact = emergencyPhone.isNotEmpty 
          ? '$emergencyName: $emergencyPhone'
          : emergencyName;
    }

    setState(() => _isSaving = true);

    try {
      await _patientService.updateProfile({
        'bloodType': _selectedBloodType,
        'height': height.isEmpty ? null : double.tryParse(height),
        'weight': weight.isEmpty ? null : double.tryParse(weight),
        'injuryType': diagnosis.isEmpty ? null : diagnosis,
        'emergencyContact': emergencyContact.isEmpty ? null : emergencyContact,
        'age': age.isEmpty ? null : int.tryParse(age),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health details saved successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _diagnosisController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _ageController.dispose();
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
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Health Details',
                                  style: GoogleFonts.leagueSpartan(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Update your medical information',
                                  style: GoogleFonts.leagueSpartan(
                                    fontSize: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                
                                _buildBloodTypeDropdown(),
                                const SizedBox(height: 20),
                                
                                _buildInputField('Age', _ageController, 'e.g., 25', keyboardType: TextInputType.number),
                                const SizedBox(height: 20),
                                _buildInputField('Height (cm)', _heightController, 'e.g., 170', keyboardType: TextInputType.number),
                                const SizedBox(height: 20),
                                _buildInputField('Weight (kg)', _weightController, 'e.g., 65', keyboardType: TextInputType.number),
                                const SizedBox(height: 20),
                                _buildInputField('Primary Diagnosis / Injury', _diagnosisController, 'Your condition'),
                                const SizedBox(height: 20),
                                
                                Text(
                                  'Emergency Contact',
                                  style: GoogleFonts.leagueSpartan(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSmallInput(
                                        _emergencyNameController,
                                        'Name',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSmallInput(
                                        _emergencyPhoneController,
                                        'Phone Number',
                                        keyboardType: TextInputType.phone,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 48),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _saveChanges,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'Save Details',
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

  Widget _buildBloodTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Blood Type',
          style: GoogleFonts.leagueSpartan(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
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
          child: DropdownButtonFormField<String>(
            initialValue: _selectedBloodType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            style: GoogleFonts.leagueSpartan(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
            items: _bloodTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedBloodType = newValue;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.leagueSpartan(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
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
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.leagueSpartan(color: AppColors.textHint),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            style: GoogleFonts.leagueSpartan(color: AppColors.textPrimary, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallInput(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return Container(
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
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.leagueSpartan(color: AppColors.textHint),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        style: GoogleFonts.leagueSpartan(color: AppColors.textPrimary, fontSize: 16),
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
              if (Navigator.canPop(context)) Navigator.pop(context, false);
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