import 'package:sqflite/sqflite.dart';
import '../data/database_helper.dart';

abstract class BaseRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  Future<Database> get database => _databaseHelper.database;
  
  String get tableName;
  
  Future<int> insert(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(tableName, data);
  }
  
  Future<List<Map<String, dynamic>>> getAll({String? orderBy}) async {
    final db = await database;
    return await db.query(tableName, orderBy: orderBy);
  }
  
  Future<Map<String, dynamic>?> getById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? maps.first : null;
  }
  
  Future<int> update(Map<String, dynamic> data, int id) async {
    final db = await database;
    return await db.update(
      tableName,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
