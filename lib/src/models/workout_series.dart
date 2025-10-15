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

  String? _sanitizeNotesForDatabase(String? input) {
  if (input == null) return null;

  String cleaned = input
      .replaceAll(RegExp(r'[\u0000-\u0008\u000B-\u000C\u000E-\u001F\u007F]'), '')
      .trim();
  if (cleaned.isEmpty || cleaned.length <= 1) return null;

  return cleaned;
}

  String? get sanitizedNotes {
    if (notes == null) return null;

    String cleaned = notes!.trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  Map<String, dynamic> toMap() {
  final sanitizedNotes = _sanitizeNotesForDatabase(notes);
  return {
    'id': id,
    'workout_exercise_id': workoutExerciseId,
    'series_number': seriesNumber,
    'repetitions': repetitions,
    'weight': weight,
    'rest_seconds': restSeconds,
    'type': type.name,
    'notes': sanitizedNotes,
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
      notes: map['notes']?.toString(),
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
    bool clearNotes = false,
  }) {
    return WorkoutSeries(
      id: id ?? this.id,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      seriesNumber: seriesNumber ?? this.seriesNumber,
      repetitions: repetitions ?? this.repetitions,
      weight: weight ?? this.weight,
      restSeconds: restSeconds ?? this.restSeconds,
      type: type ?? this.type,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
    );
  }

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

  String _formatRestTime(int seconds) {
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
        parts.add(_formatRestTime(restSeconds!));
      } else {
        parts.add('${_formatRestTime(restSeconds!)} desc');
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

  bool get hasValidNotes {
    return sanitizedNotes != null && sanitizedNotes!.isNotEmpty;
  }

  @override
  String toString() {
    return 'WorkoutSeries{id: $id, type: $type, reps: $repetitions, weight: $weight, rest: $restSeconds, notes: ${hasValidNotes ? '"${sanitizedNotes}"' : 'null'}}';
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
          sanitizedNotes == other.sanitizedNotes;

  @override
  int get hashCode =>
      id.hashCode ^
      workoutExerciseId.hashCode ^
      seriesNumber.hashCode ^
      type.hashCode ^
      repetitions.hashCode ^
      weight.hashCode ^
      restSeconds.hashCode ^
      sanitizedNotes.hashCode;
}
