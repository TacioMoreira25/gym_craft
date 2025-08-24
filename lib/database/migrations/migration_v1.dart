import 'package:sqflite/sqflite.dart';
import 'migration.dart';
import '../config/database_config.dart';
import '../../data/default_exercises.dart';

class MigrationV1 extends Migration {
  @override
  int get version => 1;
  
  @override
  String get description => 'Criação inicial das tabelas';
  
  @override
  Future<void> up(Database db) async {
    for (String query in DatabaseConfig.createTableQueries.values) {
      await db.execute(query);
    }
    
    for (String indexQuery in DatabaseConfig.createIndexQueries) {
      await db.execute(indexQuery);
    }
    
    await insertDefaultExercises(db);
  }
  
  @override
  Future<void> down(Database db) async {
    const tables = [
      DatabaseConfig.seriesTable,
      DatabaseConfig.workoutExercisesTable,
      DatabaseConfig.exercisesTable,
      DatabaseConfig.workoutsTable,
      DatabaseConfig.routinesTable,
    ];
    
    for (String table in tables) {
      await db.execute('DROP TABLE IF EXISTS $table');
    }
  }
  
  Future<void> insertDefaultExercises(Database db) async {
    final exercises = DefaultExercises.exercises;
    
    for (final exercise in exercises) {
      try {
        await db.insert(
          DatabaseConfig.exercisesTable, 
          exercise.toMap(), 
          conflictAlgorithm: ConflictAlgorithm.ignore
        );
      } catch (e) {
        print('Erro ao inserir exercício ${exercise.name}: $e');
      }
    }
  }
}