import 'package:flutter/material.dart';
import '../../data/services/database_service.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import '../../shared/constants/constants.dart';
import 'base_controller.dart';

class CreateWorkoutController extends BaseController {
  final DatabaseService _databaseService = DatabaseService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final Routine routine;

  CreateWorkoutController({required this.routine});

  List<String> get workoutSuggestions => AppConstants.workoutSuggestions;

  void applySuggestion(String suggestion) {
    nameController.text = suggestion;
    notifyListeners();
  }

  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }
    clearError();
    return true;
  }

  Future<bool> saveWorkout() async {
    if (!validateForm()) {
      return false;
    }

    setLoading(true);

    try {
      final workout = Workout(
        routineId: routine.id!,
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _databaseService.workouts.insertWorkout(workout);
      return true;
    } catch (e) {
      setError('Erro ao salvar treino: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
