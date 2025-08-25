import 'package:sqflite/sqflite.dart';
import './migrations/migration.dart';
import './migrations/migration_v1.dart';
import './migrations/migration_v2.dart';
import './migrations/migration_v3.dart';
import '../database/config/database_config.dart';

class MigrationManager {
  static final List<Migration> _migrations = [
    MigrationV1(),
    MigrationV2(),
    MigrationV3(),
  ];

  static Future<void> createDatabase(Database db, int version) async {
    print('Criando banco de dados versão $version');
    
    try {
      if (version == 1) {
        print('Executando apenas migração V1 para criação inicial');
        await MigrationV1().up(db);
        return;
      }
      
      print('Executando migração V1 (criação inicial)');
      await MigrationV1().up(db);
      
      for (int v = 2; v <= version; v++) {
        final migration = _migrations.firstWhere((m) => m.version == v);
        print('Executando migração v${migration.version}: ${migration.description}');
        await migration.up(db);
      }
      
      print('Banco de dados criado com sucesso');
      
    } catch (e) {
      print('Erro na criação do banco: $e');
      rethrow;
    }
  }

  static Future<void> upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    print('Atualizando banco de dados de v$oldVersion para v$newVersion');
    
    try {
      for (int v = oldVersion + 1; v <= newVersion; v++) {
        final migration = _migrations.firstWhere((m) => m.version == v);
        print('Executando migração v${migration.version}: ${migration.description}');
        await migration.up(db);
      }
      
      print('Upgrade do banco concluído');
      
    } catch (e) {
      print('Erro durante upgrade: $e');
      rethrow;
    }
  }

  static Future<void> downgradeDatabase(Database db, int oldVersion, int newVersion) async {
    print('Fazendo downgrade do banco de dados de v$oldVersion para v$newVersion');
    
    try {
      await resetDatabase(db);
      await createDatabase(db, newVersion);
      
      print('Downgrade concluído');
      
    } catch (e) {
      print('Erro durante downgrade: $e');
      rethrow;
    }
  }

  static Future<void> resetDatabase(Database db) async {
    print('Resetando banco de dados');
    
    const tables = [
      DatabaseConfig.seriesTable,
      DatabaseConfig.workoutExercisesTable,
      DatabaseConfig.workoutsTable,
      DatabaseConfig.exercisesTable,
      DatabaseConfig.routinesTable,
    ];

    for (String table in tables) {
      try {
        await db.execute('DROP TABLE IF EXISTS $table');
      } catch (e) {
        print('Erro ao remover tabela $table: $e');
      }
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