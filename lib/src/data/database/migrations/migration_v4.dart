import 'package:sqflite/sqflite.dart';
import 'migration.dart';

class MigrationV4 implements Migration {
  @override
  int get version => 4;

  @override
  String get description =>
      'Adiciona tabelas de histórico, medidas corporais e suporte a super-sets';

  @override
  Future<void> up(Database db) async {
    // 1. Tabela de Sessões de Treino (Histórico do dia)
    await db.execute('''
      CREATE TABLE workout_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER, -- Pode ser NULL se for um treino avulso
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        notes TEXT,
        FOREIGN KEY (workout_id) REFERENCES workouts (id)
      )
    ''');

    // 2. Tabela de Logs de Exercício (Agrupa as séries de um exercício na sessão)
    await db.execute('''
      CREATE TABLE exercise_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (session_id) REFERENCES workout_sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id)
      )
    ''');

    // Tabela de Logs de Séries (Onde fica a carga e repetição real feita)
    await db.execute('''
      CREATE TABLE set_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_log_id INTEGER NOT NULL,
        reps_performed INTEGER NOT NULL,
        weight_lifted REAL NOT NULL,
        rpe INTEGER,
        is_warmup INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (exercise_log_id) REFERENCES exercise_logs (id) ON DELETE CASCADE
      )
    ''');

    // Colunas para suporte a Super-sets na tabela workout_exercises
    await db.execute(
      'ALTER TABLE workout_exercises ADD COLUMN group_id INTEGER',
    );
    await db.execute(
      'ALTER TABLE workout_exercises ADD COLUMN super_set_order INTEGER',
    );

    // 6. Índices para performance
    await db.execute(
      'CREATE INDEX idx_set_logs_exercise_date ON set_logs(exercise_log_id, created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_workout_sessions_date ON workout_sessions(start_time)',
    );
  }

  @override
  Future<void> down(Database db) async {
    // Reverter alterações
    await db.execute('DROP INDEX IF EXISTS idx_workout_sessions_date');
    await db.execute('DROP INDEX IF EXISTS idx_set_logs_exercise_date');

    await db.execute('DROP TABLE IF EXISTS set_logs');
    await db.execute('DROP TABLE IF EXISTS exercise_logs');
    await db.execute('DROP TABLE IF EXISTS workout_sessions');
  }
}
