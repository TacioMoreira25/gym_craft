class WorkoutExercise {
  int? id;
  int workoutId;
  int exerciseId;
  int sets;
  int reps;
  double? weight;
  int? restTime; // em segundos
  int orderIndex;
  String? notes;

  WorkoutExercise({
    this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.weight,
    this.restTime,
    required this.orderIndex,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'rest_time': restTime,
      'order_index': orderIndex,
      'notes': notes,
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      id: map['id'],
      workoutId: map['workout_id'],
      exerciseId: map['exercise_id'],
      sets: map['sets'],
      reps: map['reps'],
      weight: map['weight']?.toDouble(),
      restTime: map['rest_time'],
      orderIndex: map['order_index'],
      notes: map['notes'],
    );
  }
}
