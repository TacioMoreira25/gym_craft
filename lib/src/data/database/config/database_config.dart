class DatabaseConfig {
  static const String databaseName = 'workout_app.db';
  static const int currentVersion = 3;
  
  static const String routinesTable = 'routines';
  static const String workoutsTable = 'workouts';
  static const String exercisesTable = 'exercises';
  static const String workoutExercisesTable = 'workout_exercises';
  static const String seriesTable = 'series';
  
  static const Map<String, String> createTableQueries = {
    routinesTable: '''
      CREATE TABLE $routinesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT, 
        created_at INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''',
    
    workoutsTable: '''
      CREATE TABLE $workoutsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        routine_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (routine_id) REFERENCES $routinesTable (id) ON DELETE CASCADE
      )
    ''',
    
    exercisesTable: '''
      CREATE TABLE $exercisesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        category TEXT NOT NULL,
        instructions TEXT,
        created_at INTEGER NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 1,
        image_url TEXT
      )
    ''',
    
    workoutExercisesTable: '''
      CREATE TABLE $workoutExercisesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (workout_id) REFERENCES $workoutsTable (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES $exercisesTable (id) ON DELETE CASCADE
      )
    ''',
    
    seriesTable: '''
      CREATE TABLE $seriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_exercise_id INTEGER NOT NULL,
        series_number INTEGER NOT NULL,
        repetitions INTEGER,
        weight REAL,
        rest_seconds INTEGER,
        type TEXT NOT NULL DEFAULT 'valid',
        notes TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (workout_exercise_id) REFERENCES $workoutExercisesTable (id) ON DELETE CASCADE
      )
    ''',
  };
  
  static const List<String> createIndexQueries = [
    'CREATE INDEX IF NOT EXISTS idx_workout_routine ON $workoutsTable(routine_id)',
    'CREATE INDEX IF NOT EXISTS idx_exercise_category ON $exercisesTable(category)',
    'CREATE INDEX IF NOT EXISTS idx_workout_exercise_workout ON $workoutExercisesTable(workout_id)',
    'CREATE INDEX IF NOT EXISTS idx_workout_exercise_exercise ON $workoutExercisesTable(exercise_id)',
    'CREATE INDEX IF NOT EXISTS idx_series_workout_exercise ON $seriesTable(workout_exercise_id)',
  ];
}