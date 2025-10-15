import '../repositories/routine_repository.dart';
import '../repositories/workout_repository.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/workout_exercise_repository.dart';
import '../repositories/series_repository.dart';
import '../database/database_helper.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final RoutineRepository routines = RoutineRepository();
  final WorkoutRepository workouts = WorkoutRepository();
  final ExerciseRepository exercises = ExerciseRepository();
  final WorkoutExerciseRepository workoutExercises = WorkoutExerciseRepository();
  final SeriesRepository series = SeriesRepository();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<void> resetDatabase() async {
    await _databaseHelper.resetDatabase();
  }

  Future<bool> checkDatabaseIntegrity() async {
    return await _databaseHelper.checkDatabaseIntegrity();
  }

  Future<void> forceRecreateDatabase() async {
    await _databaseHelper.forceRecreateDatabase();
  }

  Future<void> deleteRoutineComplete(int routineId) async {
    final workoutsList = await workouts.getWorkoutsByRoutine(routineId);

    for (var workout in workoutsList) {
      await workouts.deleteWorkout(workout.id!);
    }

    await routines.deleteRoutine(routineId);
  }

  Future<Map<String, dynamic>> getCompleteRoutineStats(int routineId) async {
    final routineStats = await routines.getRoutineStats(routineId);
    final workoutsList = await workouts.getWorkoutsByRoutine(routineId);

    int totalSeries = 0;
    for (var workout in workoutsList) {
      final workoutExercisesList = await workoutExercises.getWorkoutExercisesWithDetails(workout.id!);
      for (var workoutExercise in workoutExercisesList) {
        totalSeries += await series.getSeriesCount(workoutExercise.id!);
      }
    }

    return {
      ...routineStats,
      'total_series': totalSeries,
    };
  }
}
