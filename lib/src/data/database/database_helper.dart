import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'migration_manager.dart';
import 'config/database_config.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), DatabaseConfig.databaseName);

    return await openDatabase(
      path,
      version: DatabaseConfig.currentVersion,
      onCreate: MigrationManager.createDatabase,
      onUpgrade: MigrationManager.upgradeDatabase,
      onDowngrade: MigrationManager.downgradeDatabase,
    );
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await MigrationManager.resetDatabase(db);
    await MigrationManager.createDatabase(db, DatabaseConfig.currentVersion);
  }

  Future<bool> checkDatabaseIntegrity() async {
    final db = await database;
    try {
      final result = await db.rawQuery('PRAGMA integrity_check');
      return result.first['integrity_check'] == 'ok';
    } catch (e) {
      return false;
    }
  }

  Future<void> forceRecreateDatabase() async {
    try {
      String path = join(await getDatabasesPath(), DatabaseConfig.databaseName);
      await deleteDatabase(path);
      _database = null;
      await database;
      print('Banco de dados recriado com sucesso');
    } catch (e) {
      print('Erro ao recriar banco de dados: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getExerciseHistory(int exerciseId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT
        ws.created_at,
        ws.weight
      FROM series ws
      JOIN workout_exercises we ON ws.workout_exercise_id = we.id
      WHERE we.exercise_id = ?
      AND ws.weight IS NOT NULL
      AND ws.weight > 0
      AND ws.type = 'valid'
      ORDER BY ws.created_at ASC
      LIMIT 20
    ''',
      [exerciseId],
    );
  }

  Future<void> updateSeries(
    int seriesId,
    double weight,
    int reps,
    bool isDone,
    String type, {
    int? restSeconds,
  }) async {
    final db = await database;
    final Map<String, dynamic> values = {
      'weight': weight,
      'repetitions': reps,
      'type': type,
    };
    if (restSeconds != null) {
      values['rest_seconds'] = restSeconds;
    }
    await db.update('series', values, where: 'id = ?', whereArgs: [seriesId]);
  }
}
