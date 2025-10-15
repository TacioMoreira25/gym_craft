import 'base_repository.dart';
import '../../models/workout.dart';
import '../database/config/database_config.dart';

class WorkoutRepository extends BaseRepository {
  @override
  String get tableName => DatabaseConfig.workoutsTable;

  Future<int> insertWorkout(Workout workout) async {
    return await insert(workout.toMap());
  }

  Future<List<Workout>> getWorkoutsByRoutine(int routineId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'routine_id = ?',
      whereArgs: [routineId],
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) => Workout.fromMap(maps[i]));
  }

  Future<Workout?> getWorkoutById(int id) async {
    final map = await getById(id);
    return map != null ? Workout.fromMap(map) : null;
  }

  Future<int> updateWorkout(Workout workout) async {
    return await update(workout.toMap(), workout.id!);
  }

  Future<int> deleteWorkout(int id) async {
    return await delete(id);
  }

  Future<List<Workout>> getRecentWorkouts({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => Workout.fromMap(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getWorkoutWithRoutineInfo() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT w.*, r.name as routine_name
      FROM $tableName w
      JOIN ${DatabaseConfig.routinesTable} r ON w.routine_id = r.id
      ORDER BY w.created_at DESC
    ''');
  }
}
