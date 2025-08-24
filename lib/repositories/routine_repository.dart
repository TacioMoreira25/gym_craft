import 'package:sqflite/sqflite.dart';
import 'base_repository.dart';
import '../models/routine.dart';
import '../database/config/database_config.dart';

class RoutineRepository extends BaseRepository {
  @override
  String get tableName => DatabaseConfig.routinesTable;
  
  Future<int> insertRoutine(Routine routine) async {
    try {
      return await insert(routine.toMap());
    } catch (e) {
      print('Erro ao inserir rotina: $e');
      print('Dados da rotina: ${routine.toMap()}');
      rethrow;
    }
  }
  
  Future<List<Routine>> getAllRoutines() async {
    final maps = await getAll(orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => Routine.fromMap(maps[i]));
  }
  
  Future<Routine?> getRoutineById(int id) async {
    final map = await getById(id);
    return map != null ? Routine.fromMap(map) : null;
  }
  
  Future<int> updateRoutine(Routine routine) async {
    return await update(routine.toMap(), routine.id!);
  }
  
  Future<int> deleteRoutine(int id) async {
    return await delete(id);
  }
  
  Future<List<Routine>> getActiveRoutines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Routine.fromMap(maps[i]));
  }
  
  Future<int> toggleRoutineActive(int id, bool isActive) async {
    final db = await database;
    return await db.update(
      tableName,
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<Map<String, dynamic>> getRoutineStats(int routineId) async {
    final db = await database;
    
    final workoutsResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${DatabaseConfig.workoutsTable} WHERE routine_id = ?
    ''', [routineId]);
    
    final exercisesResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT we.exercise_id) as count
      FROM ${DatabaseConfig.workoutsTable} w
      JOIN ${DatabaseConfig.workoutExercisesTable} we ON w.id = we.workout_id
      WHERE w.routine_id = ?
    ''', [routineId]);

    final categoriesResult = await db.rawQuery('''
      SELECT DISTINCT e.category
      FROM ${DatabaseConfig.workoutsTable} w
      JOIN ${DatabaseConfig.workoutExercisesTable} we ON w.id = we.workout_id
      JOIN ${DatabaseConfig.exercisesTable} e ON we.exercise_id = e.id
      WHERE w.routine_id = ?
    ''', [routineId]);

    return {
      'workouts_count': Sqflite.firstIntValue(workoutsResult) ?? 0,
      'exercises_count': Sqflite.firstIntValue(exercisesResult) ?? 0,
      'categories': categoriesResult.map((e) => e['category']).toList(),
    };
  }
}