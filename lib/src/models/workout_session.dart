class WorkoutSession {
  int? id;
  int? workoutId;
  DateTime startTime;
  DateTime? endTime;
  String? notes;

  WorkoutSession({
    this.id,
    this.workoutId,
    required this.startTime,
    this.endTime,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_id': workoutId,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'],
      workoutId: map['workout_id'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time']),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'])
          : null,
      notes: map['notes'],
    );
  }
}
