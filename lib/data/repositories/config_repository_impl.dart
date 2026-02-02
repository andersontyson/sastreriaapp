import '../../domain/entities/configuracion.dart';
import '../../domain/repositories/config_repository.dart';
import '../datasources/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  final DatabaseHelper dbHelper;

  ConfigRepositoryImpl(this.dbHelper);

  @override
  Future<Configuracion?> getConfig() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'configuracion',
      where: 'id = ?',
      whereArgs: [1],
    );
    if (maps.isNotEmpty) {
      return Configuracion.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> saveConfig(Configuracion config) async {
    final db = await dbHelper.database;
    await db.insert(
      'configuracion',
      config.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
