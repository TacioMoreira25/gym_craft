import 'series_type.dart';

class WorkoutSeries {
  int? id;
  int workoutExerciseId;
  int seriesNumber;
  int? repetitions;
  double? weight;
  int? restSeconds;
  SeriesType type;
  String? notes;
  DateTime? createdAt;

  WorkoutSeries({
    this.id,
    required this.workoutExerciseId,
    required this.seriesNumber,
    this.repetitions,
    this.weight,
    this.restSeconds,
    this.type = SeriesType.valid,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_exercise_id': workoutExerciseId,
      'series_number': seriesNumber,
      'repetitions': repetitions,
      'weight': weight,
      'rest_seconds': restSeconds,
      'type': type.name,
      'notes': notes,
      'created_at': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    };
  }

  factory WorkoutSeries.fromMap(Map<String, dynamic> map) {
    return WorkoutSeries(
      id: map['id'],
      workoutExerciseId: map['workout_exercise_id'], 
      seriesNumber: map['series_number'], 
      repetitions: map['repetitions'], 
      weight: map['weight']?.toDouble(),
      restSeconds: map['rest_seconds'], 
      type: SeriesType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SeriesType.valid,
      ),
      notes: map['notes'],
      createdAt: map['created_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
          : null,
    );
  }

  WorkoutSeries copyWith({
    int? id,
    int? workoutExerciseId,
    int? seriesNumber,
    int? repetitions,
    double? weight,
    int? restSeconds,
    SeriesType? type,
    String? notes,
    DateTime? createdAt,
  }) {
    return WorkoutSeries(
      id: id ?? this.id,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      seriesNumber: seriesNumber ?? this.seriesNumber,
      repetitions: repetitions ?? this.repetitions,
      weight: weight ?? this.weight,
      restSeconds: restSeconds ?? this.restSeconds,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Métodos de utilidade
  String get typeDisplayName {
    switch (type) {
      case SeriesType.valid:
        return 'Válida';
      case SeriesType.warmup:
        return 'Aquecimento';
      case SeriesType.recognition:
        return 'Reconhecimento';
      case SeriesType.dropset:
        return 'Drop Set';
      case SeriesType.failure:
        return 'Falha';
      case SeriesType.rest:
        return 'Descanso';
      case SeriesType.negativa:
        return 'Negativa';
    }
  }

  String get summary {
    List<String> parts = [];

    if (repetitions != null) {
      parts.add('${repetitions} reps');
    }

    if (weight != null && weight! > 0) {
      parts.add('${weight}kg');
    }

    if (restSeconds != null) {
      if (type == SeriesType.rest) {
        parts.add('${restSeconds}s');
      } else {
        parts.add('${restSeconds}s descanso');
      }
    }

    return parts.isEmpty ? 'Configurar' : parts.join(' • ');
  }

  bool get isComplete {
    switch (type) {
      case SeriesType.valid:
      case SeriesType.dropset:
      case SeriesType.failure:
      case SeriesType.negativa:
        return repetitions != null && weight != null;

      case SeriesType.warmup:
      case SeriesType.recognition:
        return repetitions != null;

      case SeriesType.rest:
        return restSeconds != null;
    }
  }

  @override
  String toString() {
    return 'WorkoutSeries{id: $id, type: $type, reps: $repetitions, weight: $weight, rest: $restSeconds}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSeries &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workoutExerciseId == other.workoutExerciseId &&
          seriesNumber == other.seriesNumber &&
          type == other.type &&
          repetitions == other.repetitions &&
          weight == other.weight &&
          restSeconds == other.restSeconds &&
          notes == other.notes;

  @override
  int get hashCode =>
      id.hashCode ^
      workoutExerciseId.hashCode ^
      seriesNumber.hashCode ^
      type.hashCode ^
      repetitions.hashCode ^
      weight.hashCode ^
      restSeconds.hashCode ^
      notes.hashCode;
}