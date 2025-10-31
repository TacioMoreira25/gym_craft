import 'package:flutter/material.dart';
import '../../models/workout_series.dart';
import '../../models/series_type.dart';

class SeriesEditorController extends ChangeNotifier {
  final List<WorkoutSeries> initialSeries;
  final Function(List<WorkoutSeries>) onSeriesChanged;
  final int workoutExerciseId;

  List<WorkoutSeries> _series = [];

  SeriesEditorController({
    required this.initialSeries,
    required this.onSeriesChanged,
    required this.workoutExerciseId,
  }) {
    _series = List.from(initialSeries);
    if (_series.isEmpty) {
      addSeries(SeriesType.valid, notify: false);
    }
  }

  // Getters
  List<WorkoutSeries> get series => _series;
  int get seriesCount => _series.length;
  bool get hasMultipleSeries => _series.length > 1;

  // Notificar o parent
  void _notifyParent() {
    onSeriesChanged(List.from(_series));
  }

  // Adicionar série
  void addSeries(SeriesType type, {bool notify = true}) {
    final newSeries = WorkoutSeries(
      id: null,
      workoutExerciseId: workoutExerciseId,
      seriesNumber: _series.length + 1,
      type: type,
      repetitions: type == SeriesType.valid ? 12 : null,
      weight: type == SeriesType.rest ? null : 0.0,
      restSeconds: type == SeriesType.rest ? 30 : 60,
      notes: null,
    );

    _series.add(newSeries);
    notifyListeners();

    if (notify) _notifyParent();
  }

  // Remover série
  bool removeSeries(int index) {
    if (_series.length <= 1) {
      return false; // Não pode remover se só tem uma série
    }

    _series.removeAt(index);
    notifyListeners();
    _notifyParent();
    return true;
  }

  // Atualizar série específica
  void updateSeriesAtIndex(int index, WorkoutSeries updatedSeries) {
    if (index >= _series.length) return;

    _series[index] = updatedSeries;
    notifyListeners();
    _notifyParent();
  }

  // Atualizar séries quando widget for atualizado
  void updateInitialSeries(List<WorkoutSeries> newInitialSeries) {
    _series = List.from(newInitialSeries);
    if (_series.isEmpty) {
      addSeries(SeriesType.valid, notify: false);
    }
    notifyListeners();
  }

  // Obter descrição do tipo de série
  String getSeriesTypeDescription(SeriesType type) {
    switch (type) {
      case SeriesType.valid:
        return 'Série normal de treino';
      case SeriesType.warmup:
        return 'Série de aquecimento';
      case SeriesType.recognition:
        return 'Série de reconhecimento';
      case SeriesType.dropset:
        return 'Redução progressiva de peso';
      case SeriesType.failure:
        return 'Série até a falha muscular';
      case SeriesType.rest:
        return 'Intervalo de descanso';
      case SeriesType.negativa:
        return 'Foco na fase negativa';
    }
  }

  // Verificar se campo deve ser mostrado baseado no tipo
  bool shouldShowField(SeriesType type, String field) {
    switch (type) {
      case SeriesType.valid:
      case SeriesType.dropset:
      case SeriesType.failure:
      case SeriesType.negativa:
        return field == 'repetitions' ||
            field == 'weight' ||
            field == 'rest_seconds';
      case SeriesType.warmup:
      case SeriesType.recognition:
        return field == 'repetitions' || field == 'rest_seconds';
      case SeriesType.rest:
        return field == 'rest_seconds';
    }
  }
}
