class SetLog {
  int? id;
  int exerciseLogId;
  int repsPerformed;
  double weightLifted;
  int? rpe;
  bool isWarmup;
  DateTime createdAt;

  SetLog({
    this.id,
    required this.exerciseLogId,
    required this.repsPerformed,
    required this.weightLifted,
    this.rpe,
    this.isWarmup = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise_log_id': exerciseLogId,
      'reps_performed': repsPerformed,
      'weight_lifted': weightLifted,
      'rpe': rpe,
      'is_warmup': isWarmup ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory SetLog.fromMap(Map<String, dynamic> map) {
    return SetLog(
      id: map['id'],
      exerciseLogId: map['exercise_log_id'],
      repsPerformed: map['reps_performed'],
      weightLifted: map['weight_lifted'],
      rpe: map['rpe'],
      isWarmup: map['is_warmup'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }
}
