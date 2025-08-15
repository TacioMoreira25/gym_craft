import 'workout.dart';
import 'exercise.dart';
import 'workout_series.dart';
import 'series_type.dart';

class WorkoutExercise {
  int? id;
  int workoutId;
  int exerciseId;
  int order; 
  String? notes; 
  DateTime createdAt;

  Exercise? exercise;
  List<WorkoutSeries> series = [];

  WorkoutExercise({
    this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.order,
    this.notes,
    required this.createdAt,
    this.exercise,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'order': order,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      id: map['id'],
      workoutId: map['workout_id'],
      exerciseId: map['exercise_id'],
      order: map['order'],
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  int get totalSeries => series.length;
  
  List<WorkoutSeries> get validSeries => series.where((s) => s.type == SeriesType.valid).toList();
  
  List<WorkoutSeries> get warmupSeries => series.where((s) => s.type == SeriesType.warmup).toList();
  
  String get seriesSummary {
    if (series.isEmpty) return 'Nenhuma série';
    final validCount = validSeries.length;
    final warmupCount = warmupSeries.length;
    
    String summary = '${validCount} séries';
    if (warmupCount > 0) {
      summary += ' + ${warmupCount} aquecimento';
    }
    return summary;
  }
}