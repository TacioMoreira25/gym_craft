import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/routine.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_exercise.dart';

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
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE routines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1
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
        description TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        instructions TEXT,
        created_at INTEGER NOT NULL,
        is_custom INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL,
        rest_time INTEGER,
        order_index INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (workout_id) REFERENCES workouts (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      )
    ''');

    await _insertDefaultExercises(db);
  }

  Future<void> _insertDefaultExercises(Database db) async {
    List<Exercise> defaultExercises = [
      // Peito
      Exercise(name: 'Supino Reto', description: 'Exercício básico para peitoral', muscleGroup: 'Peito', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Supino Inclinado', description: 'Exercício para parte superior do peitoral', muscleGroup: 'Peito', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Flexão de Braço', description: 'Exercício corporal para peitoral', muscleGroup: 'Peito', createdAt: DateTime.now(), isCustom: false),
      
      // Costas
      Exercise(name: 'Remada Curvada', description: 'Exercício para desenvolvimento das costas', muscleGroup: 'Costas', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Pulldown', description: 'Exercício para dorsal', muscleGroup: 'Costas', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Barra Fixa', description: 'Exercício corporal para costas', muscleGroup: 'Costas', createdAt: DateTime.now(), isCustom: false),
      
      // Pernas
      Exercise(name: 'Agachamento', description: 'Exercício fundamental para Quadricps', muscleGroup: 'Quadricps', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Leg Press', description: 'Exercício para quadríceps e glúteos', muscleGroup: 'Quadricps', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Afundo', description: 'Exercício unilateral para Posterior', muscleGroup: 'Posterior', createdAt: DateTime.now(), isCustom: false),
      
      // Ombros
      Exercise(name: 'Desenvolvimento', description: 'Exercício base para ombros', muscleGroup: 'Ombros', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Elevação Lateral', description: 'Exercício para deltoides medial', muscleGroup: 'Ombros', createdAt: DateTime.now(), isCustom: false),
      
      // Braços
      Exercise(name: 'Rosca Bíceps', description: 'Exercício para bíceps', muscleGroup: 'Bíceps', createdAt: DateTime.now(), isCustom: false),
      Exercise(name: 'Tríceps Testa', description: 'Exercício para tríceps', muscleGroup: 'Tríceps', createdAt: DateTime.now(), isCustom: false),
    ];

    for (Exercise exercise in defaultExercises) {
      await db.insert('exercises', exercise.toMap());
    }
  }

  // === CRUD ROTINAS ===
  Future<int> insertRoutine(Routine routine) async {
    final db = await database;
    return await db.insert('routines', routine.toMap());
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
      // Se exercício já existe, retorna o ID existente
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
      orderBy: 'is_custom DESC, name ASC', // Exercícios customizados primeiro
    );
    return List.generate(maps.length, (i) => Exercise.fromMap(maps[i]));
  }

  Future<List<Exercise>> getExercisesByMuscleGroup(String muscleGroup) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'exercises',
      where: 'muscle_group = ?',
      whereArgs: [muscleGroup],
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

  // === CRUD EXERCÍCIOS DO TREINO ===
  Future<int> insertWorkoutExercise(WorkoutExercise workoutExercise) async {
    final db = await database;
    return await db.insert('workout_exercises', workoutExercise.toMap());
  }

  Future<List<Map<String, dynamic>>> getWorkoutExercises(int workoutId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT we.*, e.name as exercise_name, e.muscle_group, e.description, e.instructions
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
    return await db.delete('workout_exercises', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getWorkoutExerciseCount(int workoutId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM workout_exercises WHERE workout_id = ?
    ''', [workoutId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Método para criar exercício automaticamente quando adicionar no treino
  Future<int> getOrCreateExercise(String name, String description, String muscleGroup, {String? instructions}) async {
    // Primeiro tenta encontrar exercício existente
    Exercise? existing = await getExerciseByName(name);
    
    if (existing != null) {
      return existing.id!;
    }

    // Se não existir, cria novo
    final exercise = Exercise(
      name: name,
      description: description,
      muscleGroup: muscleGroup,
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
    final muscleGroupsResult = await db.rawQuery('''
      SELECT DISTINCT e.muscle_group
      FROM workouts w
      JOIN workout_exercises we ON w.id = we.workout_id
      JOIN exercises e ON we.exercise_id = e.id
      WHERE w.routine_id = ?
    ''', [routineId]);

    return {
      'workouts_count': Sqflite.firstIntValue(workoutsResult) ?? 0,
      'exercises_count': Sqflite.firstIntValue(exercisesResult) ?? 0,
      'muscle_groups': muscleGroupsResult.map((e) => e['muscle_group']).toList(),
    };
  }
}