import 'package:sqflite/sqflite.dart';
import 'migrations/migration.dart';
import 'migrations/migration_v1.dart';
import 'migrations/migration_v2.dart';
import 'migrations/migration_v3.dart';
import 'config/database_config.dart';

class MigrationManager {
  static final List<Migration> _migrations = [
    MigrationV1(),
    MigrationV2(),
    MigrationV3(),
  ];
  
  static Future<void> createDatabase(Database db, int version) async {
    print('Criando banco de dados versão $version');
    
    for (var migration in _migrations.where((m) => m.version <= version)) {
      print('Executando migração v${migration.version}: ${migration.description}');
      await migration.up(db);
    }
  }
  
  static Future<void> upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    print('Atualizando banco de dados de v$oldVersion para v$newVersion');
    
    final migrationsToRun = _migrations.where((m) => 
      m.version > oldVersion && m.version <= newVersion
    ).toList();
    
    for (var migration in migrationsToRun) {
      print('Executando migração v${migration.version}: ${migration.description}');
      try {
        await migration.up(db);
        print('Migração v${migration.version} executada com sucesso');
      } catch (e) {
        print('Erro na migração v${migration.version}: $e');
        rethrow;
      }
    }
  }
  
  static Future<void> downgradeDatabase(Database db, int oldVersion, int newVersion) async {
    print('Fazendo downgrade do banco de dados de v$oldVersion para v$newVersion');
    
    await resetDatabase(db);
    await createDatabase(db, newVersion);
  }
  
  static Future<void> resetDatabase(Database db) async {
    print('Resetando banco de dados');
    
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
  
  static bool needsMigration(int currentVersion, int targetVersion) {
    return currentVersion != targetVersion;
  }
  
  static List<Map<String, dynamic>> getMigrationInfo() {
    return _migrations.map((m) => {
      'version': m.version,
      'description': m.description,
    }).toList();
  }
}
