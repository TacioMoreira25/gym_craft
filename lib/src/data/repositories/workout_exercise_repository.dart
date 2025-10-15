import 'package:sqflite/sqflite.dart';
import 'base_repository.dart';
import '../../models/workout_exercise.dart';
import '../../models/exercise.dart';
import '../database/config/database_config.dart';
import 'series_repository.dart';

class WorkoutExerciseRepository extends BaseRepository {
  @override
  String get tableName => DatabaseConfig.workoutExercisesTable;

  final SeriesRepository _seriesRepository = SeriesRepository();

  Future<int> insertWorkoutExercise(WorkoutExercise workoutExercise) async {
    return await insert(workoutExercise.toMap());
  }

  Future<List<WorkoutExercise>> getWorkoutExercisesWithDetails(int workoutId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        we.*,
        e.name as exercise_name,
        e.description as exercise_description,
        e.category as exercise_category,
        e.instructions as exercise_instructions,
        e.is_custom as exercise_is_custom,
        e.created_at as exercise_created_at,
        e.image_url as exercise_image_url
      FROM $tableName we
      JOIN ${DatabaseConfig.exercisesTable} e ON we.exercise_id = e.id
      WHERE we.workout_id = ?
      ORDER BY we.order_index ASC
    ''', [workoutId]);

    List<WorkoutExercise> workoutExercises = [];

    for (var map in maps) {
      final workoutExercise = WorkoutExercise.fromMap(map);

      workoutExercise.exercise = Exercise(
        id: workoutExercise.exerciseId,
        name: map['exercise_name'],
        description: map['exercise_description'],
        category: map['exercise_category'],
        instructions: map['exercise_instructions'],
        isCustom: map['exercise_is_custom'] == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['exercise_created_at']),
        imageUrl: map['exercise_image_url'],
      );

      workoutExercise.series = await _seriesRepository.getSeriesByWorkoutExercise(workoutExercise.id!);

      workoutExercises.add(workoutExercise);
    }

    return workoutExercises;
  }

  Future<List<Map<String, dynamic>>> getWorkoutExercises(int workoutId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT we.*, e.name as exercise_name, e.category, e.description, e.instructions, e.image_url
      FROM $tableName we
      JOIN ${DatabaseConfig.exercisesTable} e ON we.exercise_id = e.id
      WHERE we.workout_id = ?
      ORDER BY we.order_index
    ''', [workoutId]);
  }

  Future<int> updateWorkoutExercise(WorkoutExercise workoutExercise) async {
    return await update(workoutExercise.toMap(), workoutExercise.id!);
  }

  Future<int> deleteWorkoutExercise(int id) async {
    await _seriesRepository.deleteSeriesByWorkoutExercise(id);

    return await delete(id);
  }

  Future<int> getWorkoutExerciseCount(int workoutId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM $tableName WHERE workout_id = ?
    ''', [workoutId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getNextWorkoutExerciseOrder(int workoutId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT MAX(order_index) as max_order FROM $tableName WHERE workout_id = ?',
      [workoutId],
    );

    final maxOrder = result.first['max_order'] as int?;
    return (maxOrder ?? 0) + 1;
  }

  Future<void> reorderWorkoutExercises(int workoutId) async {
    final db = await database;

    final List<Map<String, dynamic>> exercises = await db.query(
      tableName,
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'order_index ASC',
    );

    for (int i = 0; i < exercises.length; i++) {
      await db.update(
        tableName,
        {'order_index': i + 1},
        where: 'id = ?',
        whereArgs: [exercises[i]['id']],
      );
    }
  }

  Future<void> updateExerciseOrder(int workoutExerciseId, int newOrder) async {
    final db = await database;
    await db.update(
      tableName,
      {'order_index': newOrder},
      where: 'id = ?',
      whereArgs: [workoutExerciseId],
    );
  }

  Future<List<WorkoutExercise>> getWorkoutExercisesByExercise(int exerciseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => WorkoutExercise.fromMap(maps[i]));
  }
}
