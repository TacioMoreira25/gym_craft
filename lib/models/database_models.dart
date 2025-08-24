class WorkoutSummary {
  final int id;
  final String name;
  final String routineName;
  final int exerciseCount;
  final int seriesCount;
  final DateTime createdAt;
  
  WorkoutSummary({
    required this.id,
    required this.name,
    required this.routineName,
    required this.exerciseCount,
    required this.seriesCount,
    required this.createdAt,
  });
}

class ExerciseUsageStats {
  final int exerciseId;
  final String exerciseName;
  final int usageCount;
  final DateTime lastUsed;
  final double? averageWeight;
  final int? averageReps;
  
  ExerciseUsageStats({
    required this.exerciseId,
    required this.exerciseName,
    required this.usageCount,
    required this.lastUsed,
    this.averageWeight,
    this.averageReps,
  });
}

class RoutineProgress {
  final int routineId;
  final String routineName;
  final int totalWorkouts;
  final int completedWorkouts;
  final DateTime startDate;
  final DateTime? lastWorkout;
  final double progressPercentage;
  
  RoutineProgress({
    required this.routineId,
    required this.routineName,
    required this.totalWorkouts,
    required this.completedWorkouts,
    required this.startDate,
    this.lastWorkout,
    required this.progressPercentage,
  });
}
