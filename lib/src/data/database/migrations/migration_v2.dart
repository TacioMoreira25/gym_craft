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
    print('Iniciando migração V2');

    try {
      await _migrateRoutines(db);
      await _migrateExercises(db);
      await _migrateWorkoutExercises(db);
      await _ensureSeriesTable(db);
      await _verifyDefaultExercises(db);

      print('Migração V2 concluída com sucesso');

    } catch (e) {
      print('Erro na migração V2: $e');
      rethrow;
    }
  }

  @override
  Future<void> down(Database db) async {
    throw UnimplementedError('Rollback não implementado para migração v2');
  }

  Future<void> _migrateRoutines(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${DatabaseConfig.routinesTable}'"
      );

      if (tables.isEmpty) {
        print('Tabela routines não existe, será criada pela V1');
        return;
      }

      final tableInfo = await db.rawQuery('PRAGMA table_info(${DatabaseConfig.routinesTable})');
      bool hasIsActive = tableInfo.any((col) => col['name'] == 'is_active');
      bool hasUpdatedAt = tableInfo.any((col) => col['name'] == 'updated_at');

      if (!hasIsActive || !hasUpdatedAt) {
        print('Atualizando estrutura da tabela routines');

        await db.execute('CREATE TABLE routines_backup AS SELECT * FROM ${DatabaseConfig.routinesTable}');
        await db.execute('DROP TABLE ${DatabaseConfig.routinesTable}');

        await db.execute(DatabaseConfig.createTableQueries[DatabaseConfig.routinesTable]!);

        await db.execute('''
          INSERT INTO ${DatabaseConfig.routinesTable} (id, name, description, created_at, updated_at, is_active)
          SELECT id, name,
                 COALESCE(description, '') as description,
                 COALESCE(created_at, '${DateTime.now().toIso8601String()}') as created_at,
                 '${DateTime.now().toIso8601String()}' as updated_at,
                 1 as is_active
          FROM routines_backup
        ''');

        await db.execute('DROP TABLE routines_backup');
        print('Migração de routines concluída');
      }
    } catch (e) {
      print('Erro na migração de routines: $e');
      await db.execute('DROP TABLE IF EXISTS routines_backup');
    }
  }

  Future<void> _migrateExercises(Database db) async {
    try {
      // Verificar se tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${DatabaseConfig.exercisesTable}'"
      );

      if (tables.isEmpty) {
        print('Tabela exercises não existe, será criada pela V1');
        return;
      }

      final tableInfo = await db.rawQuery('PRAGMA table_info(${DatabaseConfig.exercisesTable})');
      bool hasMuscleGroup = tableInfo.any((col) => col['name'] == 'muscle_group');
      bool hasImageUrl = tableInfo.any((col) => col['name'] == 'image_url');

      if (!hasMuscleGroup || !hasImageUrl) {
        print('Atualizando estrutura da tabela exercises');

        await db.execute('CREATE TABLE exercises_backup AS SELECT * FROM ${DatabaseConfig.exercisesTable}');
        await db.execute('DROP TABLE ${DatabaseConfig.exercisesTable}');

        await db.execute(DatabaseConfig.createTableQueries[DatabaseConfig.exercisesTable]!);

        // Migrar dados existentes
        final existingExercises = await db.query('exercises_backup');

        for (final exercise in existingExercises) {
          await db.insert(DatabaseConfig.exercisesTable, {
            'id': exercise['id'],
            'name': exercise['name'],
            'description': exercise['description'] ?? '',
            'muscle_group': exercise['muscle_group'] ?? exercise['category'] ?? 'Outros',
            'category': exercise['category'] ?? 'Outros',
            'instructions': exercise['instructions'] ?? '',
            'created_at': exercise['created_at'] ?? DateTime.now().toIso8601String(),
            'is_custom': exercise['is_custom'] ?? 1,
            'image_url': exercise['image_url'], // Vai ser null para exercícios antigos
          });
        }

        await db.execute('DROP TABLE exercises_backup');
        print('Migração de exercises concluída');
      }
    } catch (e) {
      print('Erro na migração de exercises: $e');
      await db.execute('DROP TABLE IF EXISTS exercises_backup');
    }
  }

  Future<void> _migrateWorkoutExercises(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${DatabaseConfig.workoutExercisesTable}'"
      );

      if (tables.isEmpty) {
        print('Criando tabela workout_exercises');
        await db.execute(DatabaseConfig.createTableQueries[DatabaseConfig.workoutExercisesTable]!);
        return;
      }

      final tableInfo = await db.rawQuery('PRAGMA table_info(${DatabaseConfig.workoutExercisesTable})');
      bool hasRestTime = tableInfo.any((col) => col['name'] == 'rest_time_seconds');

      if (!hasRestTime) {
        print('Atualizando estrutura da tabela workout_exercises');

        List<Map<String, dynamic>> existingData = await db.query(DatabaseConfig.workoutExercisesTable);

        if (existingData.isNotEmpty) {
          await db.execute('CREATE TABLE workout_exercises_backup AS SELECT * FROM ${DatabaseConfig.workoutExercisesTable}');
        }

        await db.execute('DROP TABLE ${DatabaseConfig.workoutExercisesTable}');
        await db.execute(DatabaseConfig.createTableQueries[DatabaseConfig.workoutExercisesTable]!);

        // Restaurar dados se existiam
        if (existingData.isNotEmpty) {
          for (final row in existingData) {
            await db.insert(DatabaseConfig.workoutExercisesTable, {
              'id': row['id'],
              'workout_id': row['workout_id'],
              'exercise_id': row['exercise_id'],
              'order_index': row['order_index'] ?? 0,
              'rest_time_seconds': 60, // Valor padrão
              'notes': row['notes'] ?? '',
              'created_at': row['created_at'] ?? DateTime.now().toIso8601String(),
            });
          }

          await db.execute('DROP TABLE workout_exercises_backup');
        }

        print('Migração de workout_exercises concluída');
      }
    } catch (e) {
      print('Erro na migração de workout_exercises: $e');
      await db.execute('DROP TABLE IF EXISTS workout_exercises_backup');
    }
  }

  Future<void> _ensureSeriesTable(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${DatabaseConfig.seriesTable}'"
      );

      if (tables.isEmpty) {
        print('Criando tabela series');
        await db.execute(DatabaseConfig.createTableQueries[DatabaseConfig.seriesTable]!);
      } else {
        print('Tabela series já existe, pulando criação');
      }
    } catch (e) {
      print('Erro ao garantir tabela series: $e');
    }
  }

  Future<void> _verifyDefaultExercises(Database db) async {
    try {
      final exerciseCount = await db.rawQuery('SELECT COUNT(*) as count FROM ${DatabaseConfig.exercisesTable}');
      final count = exerciseCount.first['count'] as int;

      if (count == 0) {
        print('Nenhum exercício encontrado, inserindo exercícios padrão');
        await MigrationV1().insertDefaultExercises(db);
      } else {
        print('$count exercícios já existem no banco');
      }
    } catch (e) {
      print('Erro ao verificar exercícios padrão: $e');
    }
  }
}
