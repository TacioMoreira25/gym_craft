import 'package:sqflite/sqflite.dart';
import 'migration.dart';
import '../config/database_config.dart';
import 'migration_v1.dart';

class MigrationV2 extends Migration {
  @override
  int get version => 2;
  
  @override
  String get description => 'Migração para versão 2 - correção de estruturas';
  
  @override
  Future<void> up(Database db) async {
    await _migrateRoutines(db);
    await _migrateExercises(db);
    await _migrateWorkoutExercises(db);
    await _createSeriesTable(db);
    await _verifyDefaultExercises(db);
  }
  
  @override
  Future<void> down(Database db) async {
    
    throw UnimplementedError('Rollback não implementado para migração v2');
  }
  
  Future<void> _migrateRoutines(Database db) async {
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(${DatabaseConfig.routinesTable})');
      bool hasIsActive = tableInfo.any((col) => col['name'] == 'is_active');
      
      if (!hasIsActive) {
        await db.execute('CREATE TABLE routines_backup AS SELECT * FROM ${DatabaseConfig.routinesTable}');
        await db.execute('DROP TABLE ${DatabaseConfig.routinesTable}');
        
        await db.execute(DatabaseConfig.createTableQueries[DatabaseConfig.routinesTable]!);
        
        await db.execute('''
          INSERT INTO ${DatabaseConfig.routinesTable} (id, name, description, created_at, is_active)
          SELECT id, name, description, created_at, 1
          FROM routines_backup
        ''');
        
        await db.execute('DROP TABLE routines_backup');
      }
    } catch (e) {
      print('Erro na migração de rotinas: $e');
      await db.execute('DROP TABLE IF EXISTS routines_backup');
    }
  }
  
  Future<void> _migrateExercises(Database db) async {
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(${DatabaseConfig.exercisesTable})');
      bool hasMuscleGroup = tableInfo.any((col) => col['name'] == 'muscle_group');
      bool hasCategory = tableInfo.any((col) => col['name'] == 'category');
      bool hasImageUrl = tableInfo.any((col) => col['name'] == 'image_url');
      
      await db.execute('CREATE TABLE exercises_backup AS SELECT * FROM ${DatabaseConfig.exercisesTable}');
      await db.execute('DROP TABLE ${DatabaseConfig.exercisesTable}');
      
      await db.execute(DatabaseConfig.createTableQueries[DatabaseConfig.exercisesTable]!);
      
      String categoryColumn;
      if (hasMuscleGroup) {
        categoryColumn = 'muscle_group';
      } else if (hasCategory) {
        categoryColumn = 'category';
      } else {
        categoryColumn = "'Outros'";
      }
      
      String imageUrlColumn = hasImageUrl ? 'image_url' : 'NULL';
      
      await db.execute('''
        INSERT INTO ${DatabaseConfig.exercisesTable} (id, name, description, category, instructions, created_at, is_custom, image_url)
        SELECT id, name, 
               COALESCE(description, '') as description,
               COALESCE($categoryColumn, 'Outros') as category,
               instructions,
               COALESCE(created_at, ${DateTime.now().millisecondsSinceEpoch}) as created_at,
               COALESCE(is_custom, 1) as is_custom,
               $imageUrlColumn as image_url
        FROM exercises_backup
      ''');
      
      await db.execute('DROP TABLE exercises_backup');
    } catch (e) {
      print('Erro na migração de exercícios: $e');
      await db.execute('DROP TABLE IF EXISTS exercises_backup');
    }
  }
  
  Future<void> _migrateWorkoutExercises(Database db) async {
    List<Map<String, dynamic>> existingWorkoutExercises = [];
    try {
      existingWorkoutExercises = await db.query(DatabaseConfig.workoutExercisesTable);
      
      if (existingWorkoutExercises.isNotEmpty) {
        await db.execute('CREATE TABLE workout_exercises_backup AS SELECT * FROM ${DatabaseConfig.workoutExercisesTable}');
        await db.execute('DROP TABLE ${DatabaseConfig.workoutExercisesTable}');
      }
    } catch (e) {
      print('Tabela workout_exercises não existe ainda: $e');
    }
    
    await db.execute(DatabaseConfig.createTableQueries[DatabaseConfig.workoutExercisesTable]!);
    
    if (existingWorkoutExercises.isNotEmpty) {
      try {
        await db.execute('''
          INSERT INTO ${DatabaseConfig.workoutExercisesTable} (id, workout_id, exercise_id, order_index, notes, created_at)
          SELECT id, workout_id, exercise_id, order_index, notes, 
                 COALESCE(created_at, ${DateTime.now().millisecondsSinceEpoch}) as created_at
          FROM workout_exercises_backup
        ''');
        
        await db.execute('DROP TABLE workout_exercises_backup');
      } catch (e) {
        print('Erro na migração de workout_exercises: $e');
        await db.execute('DROP TABLE IF EXISTS workout_exercises_backup');
      }
    }
  }
  
  Future<void> _createSeriesTable(Database db) async {
    await db.execute(DatabaseConfig.createTableQueries[DatabaseConfig.seriesTable]!);
  }
  
  Future<void> _verifyDefaultExercises(Database db) async {
    final exerciseCount = await db.rawQuery('SELECT COUNT(*) as count FROM ${DatabaseConfig.exercisesTable}');
    if ((exerciseCount.first['count'] as int) == 0) {
      await MigrationV1().insertDefaultExercises(db);
    }
  }
}
