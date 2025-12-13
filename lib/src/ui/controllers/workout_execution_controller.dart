import 'package:flutter/material.dart';
import '../../models/workout_exercise.dart';
import '../../models/workout_series.dart';
import '../../models/series_type.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/series_repository.dart';

class WorkoutExecutionController extends ChangeNotifier {
  final int? workoutId;
  final List<WorkoutExercise> exercises;

  final HistoryRepository _historyRepository = HistoryRepository();
  final SeriesRepository _seriesRepository = SeriesRepository();

  int? _currentSessionId;
  final Set<int> _completedSeriesIds = {};
  bool _hasChanges = false;

  bool get hasChanges => _hasChanges;
  bool isSeriesCompleted(int seriesId) =>
      _completedSeriesIds.contains(seriesId);

  WorkoutExecutionController({
    required this.workoutId,
    required this.exercises,
  });

  /// Inicia a sessão de treino no banco de dados
  Future<void> initSession() async {
    if (_currentSessionId == null) {
      _currentSessionId = await _historyRepository.startSession(
        workoutId: workoutId,
        notes: 'Execução iniciada',
      );
      notifyListeners();
    }
  }

  /// Finaliza a sessão de treino
  Future<void> finishWorkout() async {
    if (_currentSessionId != null) {
      await _historyRepository.finishSession(_currentSessionId!);
    }
  }

  /// Marca/Desmarca uma série como concluída
  Future<void> toggleSeries(WorkoutSeries series, int exerciseId) async {
    _hasChanges = true;

    if (_completedSeriesIds.contains(series.id)) {
      _completedSeriesIds.remove(series.id);
    } else {
      _completedSeriesIds.add(series.id!);

      // 1. Atualiza a ficha de treino (persiste a carga para o próximo treino)
      await _seriesRepository.updateSeries(series);

      // 2. Registra no histórico
      if (_currentSessionId == null) {
        await initSession();
      }

      await _historyRepository.logSet(
        sessionId: _currentSessionId!,
        exerciseId: exerciseId,
        weight: series.weight ?? 0,
        reps: series.repetitions ?? 0,
        isWarmup:
            series.type == SeriesType.warmup ||
            series.type == SeriesType.recognition,
      );
    }
    notifyListeners();
  }

  /// Atualiza os valores de uma série (edição manual)
  Future<void> updateSeriesValues(
    WorkoutSeries series,
    double weight,
    int reps,
    int? restSeconds,
  ) async {
    series.weight = weight;
    series.repetitions = reps;
    series.restSeconds = restSeconds;

    await _seriesRepository.updateSeries(series);

    _hasChanges = true;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _historyRepository.clearAllHistory();
    notifyListeners();
  }
}
