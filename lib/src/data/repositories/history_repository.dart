import 'package:sqflite/sqflite.dart';
import 'base_repository.dart';
import '../../models/workout_session.dart';
import '../../models/exercise_log.dart';
import '../../models/set_log.dart';

class HistoryRepository extends BaseRepository {
  @override
  String get tableName => 'workout_sessions';

  // --- Sessões ---

  Future<int> startSession({int? workoutId, String? notes}) async {
    final session = WorkoutSession(
      workoutId: workoutId,
      startTime: DateTime.now(),
      notes: notes,
    );
    return await insert(session.toMap());
  }

  Future<void> finishSession(int sessionId) async {
    final db = await database;
    await db.update(
      tableName,
      {'end_time': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<WorkoutSession?> getSessionById(int id) async {
    final map = await getById(id);
    return map != null ? WorkoutSession.fromMap(map) : null;
  }

  // --- Logs de Exercício e Séries ---

  /// Registra uma série executada.
  /// Se não houver um ExerciseLog para este exercício nesta sessão, cria um.
  Future<int> logSet({
    required int sessionId,
    required int exerciseId,
    required double weight,
    required int reps,
    int? rpe,
    bool isWarmup = false,
  }) async {
    final db = await database;

    // 1. Verificar/Criar ExerciseLog
    int exerciseLogId;
    final List<Map<String, dynamic>> existingLogs = await db.query(
      'exercise_logs',
      where: 'session_id = ? AND exercise_id = ?',
      whereArgs: [sessionId, exerciseId],
    );

    if (existingLogs.isNotEmpty) {
      exerciseLogId = existingLogs.first['id'];
    } else {
      final exerciseLog = ExerciseLog(
        sessionId: sessionId,
        exerciseId: exerciseId,
      );
      exerciseLogId = await db.insert('exercise_logs', exerciseLog.toMap());
    }

    // 2. Criar SetLog
    final setLog = SetLog(
      exerciseLogId: exerciseLogId,
      repsPerformed: reps,
      weightLifted: weight,
      rpe: rpe,
      isWarmup: isWarmup,
      createdAt: DateTime.now(),
    );

    return await db.insert('set_logs', setLog.toMap());
  }

  /// Retorna o histórico completo de cargas de um exercício para gráficos
  Future<List<Map<String, dynamic>>> getExerciseHistory(int exerciseId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT
        s.created_at,
        s.weight_lifted as weight,
        s.reps_performed as reps,
        s.rpe,
        s.is_warmup,
        el.session_id
      FROM set_logs s
      JOIN exercise_logs el ON s.exercise_log_id = el.id
      WHERE el.exercise_id = ?
      ORDER BY s.created_at ASC
    ''',
      [exerciseId],
    );
  }

  /// Método de conveniência para log rápido (sem sessão prévia explícita na UI)
  /// Útil para migrar o comportamento antigo do DatabaseHelper
  Future<void> quickLog(int exerciseId, double weight, int reps) async {
    // Cria uma sessão "Quick Log"
    final sessionId = await startSession(notes: 'Quick Log');
    await logSet(
      sessionId: sessionId,
      exerciseId: exerciseId,
      weight: weight,
      reps: reps,
    );
    await finishSession(sessionId);
  }

  /// Limpa todo o histórico (Debug)
  Future<void> clearAllHistory() async {
    final db = await database;
    await db.delete('set_logs');
    await db.delete('exercise_logs');
    await db.delete('workout_sessions');
  }

  /// Limpa o histórico de um exercício específico
  Future<void> clearExerciseHistory(int exerciseId) async {
    final db = await database;
    // Delete set_logs where exercise_log_id is associated with exerciseId
    await db.execute(
      '''
      DELETE FROM set_logs
      WHERE exercise_log_id IN (
        SELECT id FROM exercise_logs WHERE exercise_id = ?
      )
    ''',
      [exerciseId],
    );

    // Delete exercise_logs for that exercise
    await db.delete(
      'exercise_logs',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );
  }
}
