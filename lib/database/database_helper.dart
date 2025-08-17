import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/routine.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_exercise.dart';
import '../models/workout_series.dart';

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
    String path = join(await getDatabasesPath(), 'workout_app.db');
    
    return await openDatabase(
      path,
      version: 2, 
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
      onDowngrade: (db, oldVersion, newVersion) async {
        await _resetAllTables(db);
        await _createTables(db, 2);
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE routines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT, 
        created_at INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        routine_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (routine_id) REFERENCES routines (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        category TEXT NOT NULL,
        instructions TEXT,
        created_at INTEGER NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (workout_id) REFERENCES workouts (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE series (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_exercise_id INTEGER NOT NULL,
        series_number INTEGER NOT NULL,
        repetitions INTEGER,
        weight REAL,
        rest_seconds INTEGER,
        type TEXT NOT NULL DEFAULT 'valid',
        notes TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (workout_exercise_id) REFERENCES workout_exercises (id) ON DELETE CASCADE
      )
    ''');

    await _insertDefaultExercises(db);
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('CREATE TABLE routines_backup AS SELECT * FROM routines');
        await db.execute('DROP TABLE routines');
        
        await db.execute('''
          CREATE TABLE routines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT, 
            created_at INTEGER NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1
          )
        ''');
        
        await db.execute('''
          INSERT INTO routines (id, name, description, created_at, is_active)
          SELECT id, name, description, created_at, COALESCE(is_active, 1)
          FROM routines_backup
        ''');
        
        await db.execute('DROP TABLE routines_backup');
      } catch (e) {
        print('Erro na migração de routines: $e');
        await db.execute('DROP TABLE IF EXISTS routines_backup');
      }
      
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(exercises)');
        bool hasMuscleGroup = tableInfo.any((col) => col['name'] == 'muscle_group');
        bool hasCategory = tableInfo.any((col) => col['name'] == 'category');
        
        await db.execute('CREATE TABLE exercises_backup AS SELECT * FROM exercises');
        await db.execute('DROP TABLE exercises');
        
        await db.execute('''
          CREATE TABLE exercises (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            category TEXT NOT NULL,
            instructions TEXT,
            created_at INTEGER NOT NULL,
            is_custom INTEGER NOT NULL DEFAULT 1
          )
        ''');
        
        String categoryColumn;
        if (hasMuscleGroup) {
          categoryColumn = 'muscle_group';
        } else if (hasCategory) {
          categoryColumn = 'category';
        } else {
          categoryColumn = "'Outros'";
        }
        
        await db.execute('''
          INSERT INTO exercises (id, name, description, category, instructions, created_at, is_custom)
          SELECT id, name, 
                 COALESCE(description, '') as description,
                 COALESCE($categoryColumn, 'Outros') as category,
                 instructions,
                 COALESCE(created_at, ${DateTime.now().millisecondsSinceEpoch}) as created_at,
                 COALESCE(is_custom, 1) as is_custom
          FROM exercises_backup
        ''');
        
        await db.execute('DROP TABLE exercises_backup');
      } catch (e) {
        print('Erro na migração de exercises: $e');
        await db.execute('DROP TABLE IF EXISTS exercises_backup');
        await _insertDefaultExercises(db);
      }
      
      List<Map<String, dynamic>> existingWorkoutExercises = [];
      try {
        existingWorkoutExercises = await db.query('workout_exercises');
        
        if (existingWorkoutExercises.isNotEmpty) {
          await db.execute('CREATE TABLE workout_exercises_backup AS SELECT * FROM workout_exercises');
          await db.execute('DROP TABLE workout_exercises');
        }
      } catch (e) {
        print('Tabela workout_exercises não existe ainda: $e');
      }
      
      await db.execute('''
        CREATE TABLE workout_exercises (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workout_id INTEGER NOT NULL,
          exercise_id INTEGER NOT NULL,
          order_index INTEGER NOT NULL,
          notes TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (workout_id) REFERENCES workouts (id) ON DELETE CASCADE,
          FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
        )
      ''');
      
      if (existingWorkoutExercises.isNotEmpty) {
        try {
          await db.execute('''
            INSERT INTO workout_exercises (id, workout_id, exercise_id, order_index, notes, created_at)
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
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS series (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workout_exercise_id INTEGER NOT NULL,
          series_number INTEGER NOT NULL,
          repetitions INTEGER,
          weight REAL,
          rest_seconds INTEGER,
          type TEXT NOT NULL DEFAULT 'valid',
          notes TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (workout_exercise_id) REFERENCES workout_exercises (id) ON DELETE CASCADE
        )
      ''');
      
      final exerciseCount = await db.rawQuery('SELECT COUNT(*) as count FROM exercises');
      if ((exerciseCount.first['count'] as int) == 0) {
        await _insertDefaultExercises(db);
      }
    }
  }

  Future<void> _insertDefaultExercises(Database db) async {
    List<Exercise> defaultExercises = [
      // Peito
      Exercise(name: 'Supino Reto', description: 'Exercício básico para peitoral', category: 'Peito', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Supino Inclinado', description: 'Exercício para parte superior do peitoral', category: 'Peito', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Flexão de Braço', description: 'Exercício corporal para peitoral', category: 'Peito', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Crucifixo', description: 'Exercício de isolamento para peitoral', category: 'Peito', createdAt: DateTime.now(), isCustom: false),
      
      // Costas
      Exercise(name: 'Remada Curvada', description: 'Exercício para desenvolvimento das costas', category: 'Costas', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Pulldown', description: 'Exercício para dorsal', category: 'Costas', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Barra Fixa', description: 'Exercício corporal para costas', category: 'Costas', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Remada Baixa', description: 'Exercício para meio das costas', category: 'Costas', createdAt: DateTime.now(), isCustom: false),
      
      // Pernas
      Exercise(name: 'Agachamento', description: 'Exercício fundamental para quadríceps', category: 'Quadríceps', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Leg Press', description: 'Exercício para quadríceps e glúteos', category: 'Quadríceps', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Afundo', description: 'Exercício unilateral para pernas', category: 'Posterior', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Stiff', description: 'Exercício para posterior de coxa', category: 'Posterior', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Panturrilha', description: 'Exercício para panturrilhas', category: 'Panturrilhas', createdAt: DateTime.now(), isCustom: false),
      
      // Ombros
      Exercise(name: 'Desenvolvimento', description: 'Exercício base para ombros', category: 'Ombros', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Elevação Lateral', description: 'Exercício para deltoides medial', category: 'Ombros', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Elevação Frontal', description: 'Exercício para deltoides anterior', category: 'Ombros', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Crucifixo Inverso', description: 'Exercício para deltoides posterior', category: 'Ombros', createdAt: DateTime.now(), isCustom: false),
      
      // Braços
      Exercise(name: 'Rosca Bíceps', description: 'Exercício para bíceps', category: 'Bíceps', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Rosca Martelo', description: 'Exercício para bíceps e antebraço', category: 'Bíceps', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Tríceps Testa', description: 'Exercício para tríceps', category: 'Tríceps', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Tríceps Pulley', description: 'Exercício para tríceps no cabo', category: 'Tríceps', createdAt: DateTime.now(), isCustom: false),
      
      // Abdomen
      Exercise(name: 'Abdominal Tradicional', description: 'Exercício básico para abdomen', category: 'Abdomen', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Prancha', description: 'Exercício isométrico para core', category: 'Abdomen', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Abdominal Oblíquo', description: 'Exercício para músculos oblíquos', category: 'Abdomen', createdAt: DateTime.now(), isCustom: false),
    ];

    for (Exercise exercise in defaultExercises) {
      try {
        await db.insert('exercises', exercise.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (e) {
        print('Erro ao inserir exercício ${exercise.name}: $e');
      }
    }
  }

  // === CRUD ROTINAS ===
  Future<int> insertRoutine(Routine routine) async {
    final db = await database;
    try {
      return await db.insert('routines', routine.toMap());
    } catch (e) {
      print('Erro ao inserir rotina: $e');
      print('Dados da rotina: ${routine.toMap()}');
      rethrow;
    }
  }

  Future<List<Routine>> getAllRoutines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'routines',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Routine.fromMap(maps[i]));
  }

  Future<Routine?> getRoutineById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'routines',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Routine.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateRoutine(Routine routine) async {
    final db = await database;
    return await db.update(
      'routines',
      routine.toMap(),
      where: 'id = ?',
      whereArgs: [routine.id],
    );
  }

  Future<int> deleteRoutine(int id) async {
    final db = await database;
    return await db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }

  // === CRUD TREINOS ===
  Future<int> insertWorkout(Workout workout) async {
    final db = await database;
    return await db.insert('workouts', workout.toMap());
  }

  Future<List<Workout>> getWorkoutsByRoutine(int routineId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workouts',
      where: 'routine_id = ?',
      whereArgs: [routineId],
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) => Workout.fromMap(maps[i]));
  }

  Future<Workout?> getWorkoutById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Workout.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateWorkout(Workout workout) async {
    final db = await database;
    return await db.update(
      'workouts',
      workout.toMap(),
      where: 'id = ?',
      whereArgs: [workout.id],
    );
  }

  Future<int> deleteWorkout(int id) async {
    final db = await database;
    return await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }

  // === CRUD EXERCÍCIOS ===
  Future<int> insertExercise(Exercise exercise) async {
    final db = await database;
    try {
      return await db.insert('exercises', exercise.toMap());
    } catch (e) {
      final existing = await getExerciseByName(exercise.name);
      if (existing != null) {
        return existing.id!;
      }
      rethrow;
    }
  }

  Future<Exercise?> getExerciseByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'exercises',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (maps.isNotEmpty) {
      return Exercise.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Exercise>> getAllExercises() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'exercises',
      orderBy: 'is_custom DESC, name ASC',
    );
    return List.generate(maps.length, (i) => Exercise.fromMap(maps[i]));
  }

  Future<List<Exercise>> getExercisesByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'exercises',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Exercise.fromMap(maps[i]));
  }

  Future<Exercise?> getExerciseById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Exercise.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateExercise(Exercise exercise) async {
    final db = await database;
    return await db.update(
      'exercises',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<bool> canDeleteExercise(int exerciseId) async {
    final db = await database;
    final List<Map<String, dynamic>> workoutExercises = await db.query(
      'workout_exercises',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );
    return workoutExercises.isEmpty;
  }

  Future<int> deleteExercise(int id) async {
    final db = await database;
    
    final canDelete = await canDeleteExercise(id);
    if (!canDelete) {
      throw Exception('Não é possível excluir este exercício pois ele está sendo usado em treinos');
    }
    
    return await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertWorkoutExercise(WorkoutExercise workoutExercise) async {
    final db = await database;
    return await db.insert('workout_exercises', workoutExercise.toMap());
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
        e.created_at as exercise_created_at
      FROM workout_exercises we
      JOIN exercises e ON we.exercise_id = e.id
      WHERE we.workout_id = ?
      ORDER BY we.order_index ASC
    ''', [workoutId]);
    
    List<WorkoutExercise> workoutExercises = [];
    
    for (var map in maps) {
      // Criar o WorkoutExercise
      final workoutExercise = WorkoutExercise.fromMap(map);
      
      // Criar o Exercise relacionado
      workoutExercise.exercise = Exercise(
        id: workoutExercise.exerciseId,
        name: map['exercise_name'],
        description: map['exercise_description'],
        category: map['exercise_category'],
        instructions: map['exercise_instructions'],
        isCustom: map['exercise_is_custom'] == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['exercise_created_at']),
      );
      
      // Buscar as séries
      workoutExercise.series = await getSeriesByWorkoutExercise(workoutExercise.id!);
      
      workoutExercises.add(workoutExercise);
    }
    
    return workoutExercises;
  }

  Future<List<Map<String, dynamic>>> getWorkoutExercises(int workoutId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT we.*, e.name as exercise_name, e.category, e.description, e.instructions
      FROM workout_exercises we
      JOIN exercises e ON we.exercise_id = e.id
      WHERE we.workout_id = ?
      ORDER BY we.order_index
    ''', [workoutId]);
  }

  Future<int> updateWorkoutExercise(WorkoutExercise workoutExercise) async {
    final db = await database;
    return await db.update(
      'workout_exercises',
      workoutExercise.toMap(),
      where: 'id = ?',
      whereArgs: [workoutExercise.id],
    );
  }

  Future<int> deleteWorkoutExercise(int id) async {
    final db = await database;
    
    // Primeiro deletar todas as séries
    await deleteSeriesByWorkoutExercise(id);
    
    // Depois deletar o workout_exercise
    return await db.delete(
      'workout_exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getWorkoutExerciseCount(int workoutId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM workout_exercises WHERE workout_id = ?
    ''', [workoutId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // === CRUD SERIES  ===
  Future<int> insertSeries(WorkoutSeries series) async {
    final db = await database;
    return await db.insert('series', series.toMap());
  }

  Future<List<WorkoutSeries>> getSeriesByWorkoutExercise(int workoutExerciseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'series',
      where: 'workout_exercise_id = ?',
      whereArgs: [workoutExerciseId],
      orderBy: 'series_number ASC',
    );
    return List.generate(maps.length, (i) => WorkoutSeries.fromMap(maps[i]));
  }

  Future<int> updateSeries(WorkoutSeries series) async {
    final db = await database;
    return await db.update(
      'series',
      series.toMap(),
      where: 'id = ?',
      whereArgs: [series.id],
    );
  }

  Future<int> deleteSeries(int id) async {
    final db = await database;
    return await db.delete('series', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSeriesByWorkoutExercise(int workoutExerciseId) async {
    final db = await database;
    return await db.delete(
      'series',
      where: 'workout_exercise_id = ?',
      whereArgs: [workoutExerciseId],
    );
  }

  // Salvar múltiplas séries de uma vez
  Future<void> saveWorkoutExerciseSeries(int workoutExerciseId, List<WorkoutSeries> seriesList) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Deletar séries existentes
      await txn.delete(
        'series',
        where: 'workout_exercise_id = ?',
        whereArgs: [workoutExerciseId],
      );
      
      // Inserir novas séries
      for (var series in seriesList) {
        series.workoutExerciseId = workoutExerciseId;
        await txn.insert('series', series.toMap());
      }
    });
  }

  // === MÉTODOS AUXILIARES ===
  
  // Buscar próximo número de ordem para um workout
  Future<int> getNextWorkoutExerciseOrder(int workoutId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT MAX(order_index) as max_order FROM workout_exercises WHERE workout_id = ?',
      [workoutId],
    );
    
    final maxOrder = result.first['max_order'] as int?;
    return (maxOrder ?? 0) + 1;
  }

  // Reordenar exercícios após exclusão
  Future<void> reorderWorkoutExercises(int workoutId) async {
    final db = await database;
    
    // Buscar todos os exercícios do workout ordenados
    final List<Map<String, dynamic>> exercises = await db.query(
      'workout_exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'order_index ASC',
    );
    
    // Atualizar a ordem
    for (int i = 0; i < exercises.length; i++) {
      await db.update(
        'workout_exercises',
        {'order_index': i + 1},
        where: 'id = ?',
        whereArgs: [exercises[i]['id']],
      );
    }
  }

  Future<int> getOrCreateExercise(String name, String description, String category, {String? instructions}) async {
    // Primeiro tenta encontrar exercício existente
    Exercise? existing = await getExerciseByName(name);
    
    if (existing != null) {
      return existing.id!;
    }

    // Se não existir, cria novo
    final exercise = Exercise(
      name: name,
      description: description,
      category: category,
      instructions: instructions,
      createdAt: DateTime.now(),
      isCustom: true,
    );

    return await insertExercise(exercise);
  }

  // Estatísticas e relatórios
  Future<Map<String, dynamic>> getRoutineStats(int routineId) async {
    final db = await database;
    
    // Número de treinos na rotina
    final workoutsResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM workouts WHERE routine_id = ?
    ''', [routineId]);
    
    // Número total de exercícios únicos na rotina
    final exercisesResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT we.exercise_id) as count
      FROM workouts w
      JOIN workout_exercises we ON w.id = we.workout_id
      WHERE w.routine_id = ?
    ''', [routineId]);

    // Grupos musculares trabalhados
    final categoriesResult = await db.rawQuery('''
      SELECT DISTINCT e.category
      FROM workouts w
      JOIN workout_exercises we ON w.id = we.workout_id
      JOIN exercises e ON we.exercise_id = e.id
      WHERE w.routine_id = ?
    ''', [routineId]);

    return {
      'workouts_count': Sqflite.firstIntValue(workoutsResult) ?? 0,
      'exercises_count': Sqflite.firstIntValue(exercisesResult) ?? 0,
      'categories': categoriesResult.map((e) => e['category']).toList(),
    };
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await _resetAllTables(db);
    await _createTables(db, 2);
  }
  
  Future<void> _resetAllTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS series');
    await db.execute('DROP TABLE IF EXISTS workout_exercises');
    await db.execute('DROP TABLE IF EXISTS exercises');
    await db.execute('DROP TABLE IF EXISTS workouts');
    await db.execute('DROP TABLE IF EXISTS routines');
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
  
  // Método para forçar recriação do banco de dados
  Future<void> forceRecreateDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'workout_app.db');
      await deleteDatabase(path);
      _database = null; // Forçar reinicialização
      await database; // Recriar banco
      print('Banco de dados recriado com sucesso');
    } catch (e) {
      print('Erro ao recriar banco de dados: $e');
      rethrow;
    }
  }
}