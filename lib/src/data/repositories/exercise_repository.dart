import 'base_repository.dart';
import '../../models/exercise.dart';
import '../database/config/database_config.dart';

class ExerciseRepository extends BaseRepository {
  @override
  String get tableName => DatabaseConfig.exercisesTable;

  Future<int> insertExercise(Exercise exercise) async {
    try {
      return await insert(exercise.toMap());
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
      tableName,
      where: 'name = ?',
      whereArgs: [name],
    );
    return maps.isNotEmpty ? Exercise.fromMap(maps.first) : null;
  }

  Future<List<Exercise>> getAllExercises() async {
    final maps = await getAll(orderBy: 'is_custom DESC, name ASC');
    return List.generate(maps.length, (i) => Exercise.fromMap(maps[i]));
  }

  Future<List<Exercise>> getExercisesByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Exercise.fromMap(maps[i]));
  }

  Future<Exercise?> getExerciseById(int id) async {
    final map = await getById(id);
    return map != null ? Exercise.fromMap(map) : null;
  }

  Future<int> updateExercise(Exercise exercise) async {
    return await update(exercise.toMap(), exercise.id!);
  }

  Future<bool> canDeleteExercise(int exerciseId) async {
    final db = await database;
    final List<Map<String, dynamic>> workoutExercises = await db.query(
      DatabaseConfig.workoutExercisesTable,
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );
    return workoutExercises.isEmpty;
  }

  Future<int> deleteExercise(int id) async {
    final canDelete = await canDeleteExercise(id);
    if (!canDelete) {
      throw Exception('Não é possível excluir este exercício pois ele está sendo usado em treinos');
    }
    return await delete(id);
  }

  Future<int> getOrCreateExercise(String name, String description, String category, {String? instructions, String? imageUrl}) async {
    Exercise? existing = await getExerciseByName(name);

    if (existing != null) {
      return existing.id!;
    }

    final exercise = Exercise(
      name: name,
      description: description,
      category: category,
      instructions: instructions,
      createdAt: DateTime.now(),
      isCustom: true,
      imageUrl: imageUrl,
    );

    return await insertExercise(exercise);
  }

  Future<List<String>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT DISTINCT category FROM $tableName ORDER BY category ASC'
    );
    return result.map((row) => row['category'] as String).toList();
  }

  Future<List<Exercise>> getCustomExercises() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_custom = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Exercise.fromMap(maps[i]));
  }

  Future<List<Exercise>> getExercisesWithImages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'image_url IS NOT NULL AND image_url != ""',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Exercise.fromMap(maps[i]));
  }

  Future<List<Exercise>> getExercisesWithoutImages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'image_url IS NULL OR image_url = ""',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Exercise.fromMap(maps[i]));
  }

  Future<int> updateExerciseImage(int exerciseId, String? imageUrl) async {
    final db = await database;
    return await db.update(
      tableName,
      {'image_url': imageUrl},
      where: 'id = ?',
      whereArgs: [exerciseId],
    );
  }

  Future<List<Exercise>> searchExercises(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Exercise.fromMap(maps[i]));
  }
}
