import 'package:flutter/material.dart';
import '../../models/workout_exercise.dart';
import '../../models/workout_series.dart';
import '../../data/services/database_service.dart';
import '../controllers/base_controller.dart';

class EditWorkoutExerciseController extends BaseController {
  final Map<String, dynamic> workoutExerciseData;
  final VoidCallback onUpdated;

  final DatabaseService _databaseService = DatabaseService();
  final formKey = GlobalKey<FormState>();
  late TextEditingController notesController;

  List<WorkoutSeries> _series = [];
  bool _isSaving = false;

  EditWorkoutExerciseController({
    required this.workoutExerciseData,
    required this.onUpdated,
  }) {
    notesController = TextEditingController(
      text: workoutExerciseData['notes'] ?? '',
    );
    loadSeries();
  }

  // Getters
  List<WorkoutSeries> get series => _series;
  bool get isSaving => _isSaving;
  String get exerciseName =>
      workoutExerciseData['exercise_name'] ?? 'Exercício';
  String? get exerciseImageUrl => workoutExerciseData['image_url'];
  String? get exerciseCategory => workoutExerciseData['category'];
  int get workoutExerciseId => workoutExerciseData['id'];

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  // Carregamento de séries
  Future<void> loadSeries() async {
    setLoading(true);

    try {
      final seriesList = await _databaseService.series
          .getSeriesByWorkoutExercise(workoutExerciseId);

      _series = List.from(seriesList);
      setLoading(false);
    } catch (e) {
      setError('Erro ao carregar séries: $e');
    }
  }

  // Atualizar séries quando o widget filho notifica
  void onSeriesChanged(List<WorkoutSeries> updatedSeries) {
    if (!_isSaving) {
      _series = List.from(updatedSeries);
      notifyListeners();
    }
  }

  // Atualizar exercício do treino
  Future<bool> updateWorkoutExercise() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (_isSaving) return false;

    _isSaving = true;
    notifyListeners();

    try {
      final notesText = notesController.text.trim();

      final workoutExercise = WorkoutExercise(
        id: workoutExerciseData['id'],
        workoutId: workoutExerciseData['workout_id'],
        exerciseId: workoutExerciseData['exercise_id'],
        orderIndex: workoutExerciseData['order_index'],
        notes: notesText.isEmpty ? null : notesText,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          workoutExerciseData['created_at'],
        ),
      );

      await _databaseService.workoutExercises.updateWorkoutExercise(
        workoutExercise,
      );

      await _updateSeriesInDatabase();

      onUpdated();
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      setError('Erro ao atualizar exercício: $e');
      return false;
    }
  }

  Future<void> _updateSeriesInDatabase() async {
    // Remove séries existentes
    await _databaseService.series.deleteSeriesByWorkoutExercise(
      workoutExerciseId,
    );

    // Insere séries atualizadas
    for (int i = 0; i < _series.length; i++) {
      final s = _series[i];
      final newSeries = s.copyWith(
        id: null, // Reset ID para inserção
        workoutExerciseId: workoutExerciseId,
        seriesNumber: i + 1,
      );
      await _databaseService.series.insertSeries(newSeries);
    }
  }
}
