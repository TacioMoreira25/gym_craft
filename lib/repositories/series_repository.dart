import 'package:sqflite/sqflite.dart';
import 'base_repository.dart';
import '../models/workout_series.dart';
import '../database/config/database_config.dart';

class SeriesRepository extends BaseRepository {
  @override
  String get tableName => DatabaseConfig.seriesTable;
  
  Future<int> insertSeries(WorkoutSeries series) async {
    return await insert(series.toMap());
  }
  
  Future<List<WorkoutSeries>> getSeriesByWorkoutExercise(int workoutExerciseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'workout_exercise_id = ?',
      whereArgs: [workoutExerciseId],
      orderBy: 'series_number ASC',
    );
    return List.generate(maps.length, (i) => WorkoutSeries.fromMap(maps[i]));
  }
  
  Future<int> updateSeries(WorkoutSeries series) async {
    return await update(series.toMap(), series.id!);
  }
  
  Future<int> deleteSeries(int id) async {
    return await delete(id);
  }
  
  Future<int> deleteSeriesByWorkoutExercise(int workoutExerciseId) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'workout_exercise_id = ?',
      whereArgs: [workoutExerciseId],
    );
  }
  
  Future<void> saveWorkoutExerciseSeries(int workoutExerciseId, List<WorkoutSeries> seriesList) async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.delete(
        tableName,
        where: 'workout_exercise_id = ?',
        whereArgs: [workoutExerciseId],
      );
      
      for (var series in seriesList) {
        series.workoutExerciseId = workoutExerciseId;
        await txn.insert(tableName, series.toMap());
      }
    });
  }
  
  Future<List<WorkoutSeries>> getSeriesByType(int workoutExerciseId, String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'workout_exercise_id = ? AND type = ?',
      whereArgs: [workoutExerciseId, type],
      orderBy: 'series_number ASC',
    );
    return List.generate(maps.length, (i) => WorkoutSeries.fromMap(maps[i]));
  }
  
  Future<Map<String, dynamic>> getSeriesStats(int workoutExerciseId) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_series,
        SUM(repetitions) as total_reps,
        AVG(weight) as avg_weight,
        MAX(weight) as max_weight,
        SUM(rest_seconds) as total_rest
      FROM $tableName 
      WHERE workout_exercise_id = ? AND type = 'valid'
    ''', [workoutExerciseId]);
    
    return result.first;
  }
  
  Future<int> getSeriesCount(int workoutExerciseId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM $tableName 
      WHERE workout_exercise_id = ?
    ''', [workoutExerciseId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  Future<void> duplicateSeries(int sourceWorkoutExerciseId, int targetWorkoutExerciseId) async {
    final sourceSeries = await getSeriesByWorkoutExercise(sourceWorkoutExerciseId);
    final newSeries = sourceSeries.map((series) => WorkoutSeries(
      workoutExerciseId: targetWorkoutExerciseId,
      seriesNumber: series.seriesNumber,
      repetitions: series.repetitions,
      weight: series.weight,
      restSeconds: series.restSeconds,
      type: series.type,
      notes: series.notes,
      createdAt: DateTime.now(),
    )).toList();
    
    for (var series in newSeries) {
      await insertSeries(series);
    }
  }
}