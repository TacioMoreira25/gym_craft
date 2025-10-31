import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../models/workout_exercise.dart';
import '../../models/workout_series.dart';
import '../../models/series_type.dart';
import '../../data/services/database_service.dart';
import '../controllers/base_controller.dart';

class AddWorkoutExerciseController extends BaseController {
  final int workoutId;
  final Exercise selectedExercise;
  final VoidCallback onExerciseAdded;

  final DatabaseService _databaseService = DatabaseService();
  final formKey = GlobalKey<FormState>();
  final notesController = TextEditingController();

  List<WorkoutSeries> _series = [];

  AddWorkoutExerciseController({
    required this.workoutId,
    required this.selectedExercise,
    required this.onExerciseAdded,
  }) {
    _initializeDefaultSeries();
  }

  // Getters
  List<WorkoutSeries> get series => _series;
  String get exerciseName => selectedExercise.name;
  String get exerciseCategory => selectedExercise.category;
  String? get exerciseDescription => selectedExercise.description;
  String? get exerciseImageUrl => selectedExercise.imageUrl;
  bool get hasDescription => selectedExercise.description?.isNotEmpty == true;

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  void _initializeDefaultSeries() {
    _series = [
      WorkoutSeries(
        workoutExerciseId: 0, // Temporário
        seriesNumber: 1,
        repetitions: 12,
        weight: 0.0,
        restSeconds: 60,
        type: SeriesType.valid,
        createdAt: DateTime.now(),
      ),
      WorkoutSeries(
        workoutExerciseId: 0, // Temporário
        seriesNumber: 2,
        repetitions: 12,
        weight: 0.0,
        restSeconds: 60,
        type: SeriesType.valid,
        createdAt: DateTime.now(),
      ),
      WorkoutSeries(
        workoutExerciseId: 0, // Temporário
        seriesNumber: 3,
        repetitions: 12,
        weight: 0.0,
        restSeconds: 60,
        type: SeriesType.valid,
        createdAt: DateTime.now(),
      ),
    ];
  }

  // Atualizar séries quando o widget filho notifica
  void onSeriesChanged(List<WorkoutSeries> updatedSeries) {
    if (!isLoading) {
      _series = List.from(updatedSeries);
      notifyListeners();
    }
  }

  // Salvar exercício no treino
  Future<bool> addExerciseToWorkout() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    setLoading(true);

    try {
      final nextOrder = await _databaseService.workoutExercises
          .getNextWorkoutExerciseOrder(workoutId);

      final workoutExercise = WorkoutExercise(
        workoutId: workoutId,
        exerciseId: selectedExercise.id!,
        orderIndex: nextOrder,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      final workoutExerciseId = await _databaseService.workoutExercises
          .insertWorkoutExercise(workoutExercise);

      List<WorkoutSeries> seriesList = [];
      for (int i = 0; i < _series.length; i++) {
        final s = _series[i];
        final series = s.copyWith(
          id: null, // Reset ID para inserção
          workoutExerciseId: workoutExerciseId,
          seriesNumber: i + 1,
        );
        seriesList.add(series);
      }

      await _databaseService.series.saveWorkoutExerciseSeries(
        workoutExerciseId,
        seriesList,
      );

      onExerciseAdded();
      setLoading(false);
      return true;
    } catch (e) {
      setError('Erro ao adicionar exercício: $e');
      return false;
    }
  }

  // Mensagens de sucesso/erro
  String get successMessage => '$exerciseName adicionado ao treino!';
}
