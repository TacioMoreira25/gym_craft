import 'package:sqflite/sqflite.dart';
import '../models/workout_series.dart';
import 'base_repository.dart';
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
    // O toMap() do WorkoutSeries já trata a sanitização das notas
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
      // Remove todas as séries existentes
      await txn.delete(
        tableName,
        where: 'workout_exercise_id = ?',
        whereArgs: [workoutExerciseId],
      );

      // Insere as novas séries
      for (int i = 0; i < seriesList.length; i++) {
        final series = seriesList[i];
        series.workoutExerciseId = workoutExerciseId;
        series.seriesNumber = i + 1; // Garante numeração sequencial

        // Cria um mapa sanitizado para inserção
        final seriesMap = series.toMap();

        // Remove o ID para inserção (será gerado automaticamente)
        seriesMap.remove('id');

        await txn.insert(tableName, seriesMap);
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
      notes: series.sanitizedNotes,
      createdAt: DateTime.now(),
    )).toList();

    for (var series in newSeries) {
      await insertSeries(series);
    }
  }

  Future<void> cleanupExistingNotes() async {
    final db = await database;

    // Busca todas as séries com notas
    final List<Map<String, dynamic>> seriesWithNotes = await db.query(
      tableName,
      where: 'notes IS NOT NULL AND notes != ""',
    );

    for (final seriesMap in seriesWithNotes) {
      final series = WorkoutSeries.fromMap(seriesMap);

      if (series.sanitizedNotes != series.notes) {
        await db.update(
          tableName,
          {'notes': series.sanitizedNotes},
          where: 'id = ?',
          whereArgs: [series.id],
        );
      }
    }
  }

  // Método para debug - listar séries com caracteres problemáticos
  Future<List<WorkoutSeries>> getSeriesWithProblematicNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);

    final allSeries = List.generate(maps.length, (i) => WorkoutSeries.fromMap(maps[i]));

    // Filtra séries onde as notas originais diferem das sanitizadas
    return allSeries.where((series) =>
      series.notes != null &&
      series.sanitizedNotes != series.notes
    ).toList();
  }
}
