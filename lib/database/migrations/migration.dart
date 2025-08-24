import 'package:sqflite/sqflite.dart';

abstract class Migration {
  int get version;
  String get description;
  
  Future<void> up(Database db);
  Future<void> down(Database db);
}