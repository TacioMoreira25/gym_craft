import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/database_service.dart';
import '../../models/workout.dart';
import '../../models/workout_exercise.dart';
import '../../models/workout_series.dart';
import '../../models/series_type.dart';
import 'base_controller.dart';

class WorkoutDetailController extends BaseController {
  final DatabaseService _databaseService = DatabaseService();
  final Workout workout;

  List<WorkoutExercise> _workoutExercises = [];
  bool _isReorderMode = false;
  final Set<int> _expandedExercises = {};
  final TextEditingController searchController = TextEditingController();

  WorkoutDetailController({required this.workout});

  // Getters
  List<WorkoutExercise> get workoutExercises => _workoutExercises;
  bool get isReorderMode => _isReorderMode;
  Set<int> get expandedExercises => _expandedExercises;
  bool get hasExercises => _workoutExercises.isNotEmpty;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Carregamento de dados
  Future<void> loadWorkoutExercises() async {
    setLoading(true);
    try {
      final exercises = await _databaseService.workoutExercises
          .getWorkoutExercisesWithDetails(workout.id!);

      final orderedExercises = await _applyCustomOrder(exercises);
      _workoutExercises = orderedExercises;
      setLoading(false);
    } catch (e) {
      setError('Erro ao carregar exercícios: $e');
    }
  }

  Future<List<WorkoutExercise>> _applyCustomOrder(
    List<WorkoutExercise> exercises,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedOrder = prefs.getString('exercise_order_${workout.id}');

      if (savedOrder == null) {
        return exercises;
      }

      List<int> orderIds = List<int>.from(jsonDecode(savedOrder));
      List<WorkoutExercise> orderedExercises = [];

      for (int id in orderIds) {
        final exercise = exercises.where((e) => e.id == id).firstOrNull;
        if (exercise != null) {
          orderedExercises.add(exercise);
        }
      }

      for (WorkoutExercise exercise in exercises) {
        if (!orderedExercises.any((e) => e.id == exercise.id)) {
          orderedExercises.add(exercise);
        }
      }

      return orderedExercises;
    } catch (e) {
      return exercises;
    }
  }

  // Gerenciamento de exercícios
  Future<void> deleteExercise(WorkoutExercise workoutExercise) async {
    try {
      await _databaseService.workoutExercises.deleteWorkoutExercise(
        workoutExercise.id!,
      );
      await loadWorkoutExercises();
    } catch (e) {
      setError('Erro ao remover exercício: $e');
    }
  }

  Future<void> updateWorkoutExercise(Map<String, dynamic> exerciseData) async {
    try {
      // A lógica de atualização será implementada via dialog
      await loadWorkoutExercises();
    } catch (e) {
      setError('Erro ao atualizar exercício: $e');
    }
  }

  // Reordenação
  void setReorderMode(bool enabled) {
    _isReorderMode = enabled;
    notifyListeners();
  }

  void exitReorderMode() {
    _isReorderMode = false;
    notifyListeners();
  }

  void reorderExercises(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final WorkoutExercise item = _workoutExercises.removeAt(oldIndex);
    _workoutExercises.insert(newIndex, item);
    notifyListeners();
  }

  Future<void> saveExerciseOrder() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<int> exerciseIds = _workoutExercises
          .map((exercise) => exercise.id!)
          .toList();
      await prefs.setString(
        'exercise_order_${workout.id}',
        jsonEncode(exerciseIds),
      );
    } catch (e) {
      setError('Erro ao salvar ordem dos exercícios: $e');
    }
  }

  // Expansão de exercícios
  void toggleExerciseExpansion(int exerciseId) {
    if (_expandedExercises.contains(exerciseId)) {
      _expandedExercises.remove(exerciseId);
    } else {
      _expandedExercises.add(exerciseId);
    }
    notifyListeners();
  }

  bool isExerciseExpanded(int exerciseId) {
    return _expandedExercises.contains(exerciseId);
  }

  // Cálculos e estatísticas
  int getTotalSeries() {
    return _workoutExercises.fold<int>(0, (sum, ex) => sum + ex.series.length);
  }

  int calculateEstimatedTime() {
    int totalTime = 0;
    for (final workoutExercise in _workoutExercises) {
      final series = workoutExercise.series;

      for (final s in series) {
        if (s.type == SeriesType.rest) {
          totalTime += s.restSeconds ?? 30;
        } else {
          totalTime += 30;
          if (s.restSeconds != null) {
            totalTime += s.restSeconds!;
          }
        }
      }
    }
    return (totalTime / 60).ceil();
  }

  // Utilitários de formatação
  String formatRestTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '${minutes}min';
      } else {
        return '${minutes}min ${remainingSeconds}s';
      }
    }
  }

  bool isValidText(String? text) {
    if (text == null) return false;

    final cleanText = text.replaceAll(
      RegExp(r'[\s\u0000-\u001F\u007F-\u009F\uFEFF\u200B-\u200D\uFFF0-\uFFFF]'),
      '',
    );

    return cleanText.isNotEmpty;
  }

  String buildSeriesText(
    WorkoutSeries series,
    int seriesNumber,
    String typeName,
  ) {
    switch (series.type) {
      case SeriesType.rest:
        return ' ${formatRestTime(series.restSeconds ?? 0)}';

      case SeriesType.warmup:
      case SeriesType.recognition:
        return '${series.repetitions ?? 0} reps | ${formatRestTime(series.restSeconds!)} pausa';

      default:
        String text = '${series.repetitions ?? 0} reps';
        if (series.weight != null && series.weight! > 0) {
          text += ' | ${series.weight}kg';
        }
        if (series.restSeconds != null && series.restSeconds! > 0) {
          text += ' | ${formatRestTime(series.restSeconds!)} pausa';
        }
        return text;
    }
  }

  // Preparação de dados para edição
  Map<String, dynamic> prepareExerciseDataForEdit(
    WorkoutExercise workoutExercise,
  ) {
    return {
      'id': workoutExercise.id,
      'workout_id': workoutExercise.workoutId,
      'exercise_id': workoutExercise.exerciseId,
      'order_index': workoutExercise.orderIndex,
      'notes': workoutExercise.notes,
      'created_at': workoutExercise.createdAt.millisecondsSinceEpoch,
      'exercise_name': workoutExercise.exercise?.name ?? 'Exercício',
      'category': workoutExercise.exercise?.category ?? '',
      'description': workoutExercise.exercise?.description ?? '',
      'instructions': workoutExercise.exercise?.instructions ?? '',
      'image_url': workoutExercise.exercise?.imageUrl,
    };
  }

  // Obter IDs de exercícios existentes para exclusão na seleção
  List<int> getExistingExerciseIds() {
    return _workoutExercises.map((we) => we.exerciseId).toList();
  }
}
