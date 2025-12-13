class ExerciseLog {
  int? id;
  int sessionId;
  int exerciseId;
  String? notes;

  ExerciseLog({
    this.id,
    required this.sessionId,
    required this.exerciseId,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'notes': notes,
    };
  }

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      id: map['id'],
      sessionId: map['session_id'],
      exerciseId: map['exercise_id'],
      notes: map['notes'],
    );
  }
}
