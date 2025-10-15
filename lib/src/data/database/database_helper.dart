import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'migration_manager.dart';
import 'config/database_config.dart';

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
    String path = join(await getDatabasesPath(), DatabaseConfig.databaseName);

    return await openDatabase(
      path,
      version: DatabaseConfig.currentVersion,
      onCreate: MigrationManager.createDatabase,
      onUpgrade: MigrationManager.upgradeDatabase,
      onDowngrade: MigrationManager.downgradeDatabase,
    );
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await MigrationManager.resetDatabase(db);
    await MigrationManager.createDatabase(db, DatabaseConfig.currentVersion);
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

  Future<void> forceRecreateDatabase() async {
    try {
      String path = join(await getDatabasesPath(), DatabaseConfig.databaseName);
      await deleteDatabase(path);
      _database = null;
      await database;
      print('Banco de dados recriado com sucesso');
    } catch (e) {
      print('Erro ao recriar banco de dados: $e');
      rethrow;
    }
  }
}
