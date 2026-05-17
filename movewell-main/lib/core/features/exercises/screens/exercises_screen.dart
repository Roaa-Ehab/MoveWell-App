import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movewell/core/theme/colors.dart';
import 'package:movewell/core/widgets/header_background.dart';
import 'package:movewell/core/services/patient_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final PatientService _patientService = PatientService();
  List<dynamic> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
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

  void _getAIRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final patientData = await _patientService.getProfile();
      
      final response = await Dio().post(
        'https://smashup-marshy-kindly.ngrok-free.dev/api/ai/recommend',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'injury_type': patientData['injuryType'] ?? 'back',
          'age': patientData['age'] ?? 30,
          'weight_kg': patientData['weight'] ?? 70,
          'pain_level': patientData['pain_level'] ?? 5,
        },
      );
      
      final recommendations = response.data['recommendations'];
      final exerciseNames = recommendations.map((r) => '• ${r['name']}').join('\n');
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Recommended Exercises',
                  style: GoogleFonts.leagueSpartan(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(exerciseNames),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _predictRecovery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final patientData = await _patientService.getProfile();
      
      final response = await Dio().post(
        'https://smashup-marshy-kindly.ngrok-free.dev/api/ai/predict-recovery',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'pain_level': patientData['pain_level'] ?? 5,
          'age': patientData['age'] ?? 30,
        },
      );
      
      final outcome = response.data['predicted_outcome'];
      final confidence = response.data['confidence'];
      
      Color outcomeColor;
      String recommendation;
      if (outcome == 'improving') {
        outcomeColor = Colors.green;
        recommendation = 'Continue your current plan. Great progress!';
      } else if (outcome == 'stable') {
        outcomeColor = Colors.orange;
        recommendation = 'Stay consistent with your exercises.';
      } else {
        outcomeColor = Colors.red;
        recommendation = 'Please consult your doctor for plan adjustment.';
      }
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Recovery Prediction',
                  style: GoogleFonts.leagueSpartan(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Outcome: ', style: GoogleFonts.leagueSpartan(fontWeight: FontWeight.w600)),
                  Text(outcome.toUpperCase(), style: GoogleFonts.leagueSpartan(fontWeight: FontWeight.bold, color: outcomeColor)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Confidence: ${(confidence * 100).toInt()}%', style: GoogleFonts.leagueSpartan()),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(recommendation, style: GoogleFonts.leagueSpartan(fontSize: 13))),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('OK', style: GoogleFonts.leagueSpartan(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'All Exercises',
                                style: GoogleFonts.leagueSpartan(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: _predictRecovery,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.trending_up_rounded, color: Color(0xFF4ECDC4), size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Recovery',
                                            style: GoogleFonts.leagueSpartan(
                                              color: const Color(0xFF4ECDC4),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _getAIRecommendations,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            'AI',
                                            style: GoogleFonts.leagueSpartan(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (_exercises.isEmpty)
                            Center(
                              child: Text(
                                'No exercises available',
                                style: GoogleFonts.leagueSpartan(color: AppColors.textMuted),
                              ),
                            )
                          else
                            ..._exercises.map((ex) => _buildExerciseCard(ex)),
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

  Widget _buildExerciseCard(dynamic exercise) {
    return GestureDetector(
      onTap: () => _showExerciseDetail(exercise),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise['name'] ?? 'Exercise',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exercise['duration'] ?? 5} mins • ${exercise['difficulty'] ?? 'Beginner'}',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  void _showExerciseDetail(dynamic exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
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
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise['name'] ?? 'Exercise',
                            style: GoogleFonts.leagueSpartan(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${exercise['duration'] ?? 5} mins • ${exercise['difficulty'] ?? 'Beginner'}',
                            style: GoogleFonts.leagueSpartan(fontSize: 14, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.border),
                const SizedBox(height: 16),
                Text('Description', style: GoogleFonts.leagueSpartan(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  exercise['description'] ?? 'No description available',
                  style: GoogleFonts.leagueSpartan(fontSize: 14, color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 20),
                Text('Instructions', style: GoogleFonts.leagueSpartan(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  exercise['instructions']?.isNotEmpty == true
                      ? (exercise['instructions'] as List).join('\n• ')
                      : '• Perform with proper form\n• Breathe steadily\n• Stop if you feel pain',
                  style: GoogleFonts.leagueSpartan(fontSize: 14, color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Start Exercise', style: GoogleFonts.leagueSpartan(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderTopArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
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
        ],
      ),
    );
  }
}