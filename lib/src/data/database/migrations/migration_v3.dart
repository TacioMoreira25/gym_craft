import 'package:sqflite/sqflite.dart';
import 'migration.dart';
import '../config/database_config.dart';

class MigrationV3 extends Migration {
  @override
  int get version => 3;
  
  @override
  String get description => 'Adicionar coluna image_url se não existir';
  
  @override
  Future<void> up(Database db) async {
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(${DatabaseConfig.exercisesTable})');
      bool hasImageUrl = tableInfo.any((col) => col['name'] == 'image_url');
      
      if (!hasImageUrl) {
        await db.execute('ALTER TABLE ${DatabaseConfig.exercisesTable} ADD COLUMN image_url TEXT');
        print('Coluna image_url adicionada com sucesso');
      }
    } catch (e) {
      print('Erro ao adicionar coluna image_url: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> down(Database db) async {
    print('Rollback da migração v3 não implementado (SQLite não suporta DROP COLUMN)');
  }
}
