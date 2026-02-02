import '../../domain/entities/configuracion.dart';
import '../../domain/repositories/config_repository.dart';
import '../datasources/database_helper.dart';
import '../models/config_model.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  final DatabaseHelper dbHelper;

  ConfigRepositoryImpl(this.dbHelper);

  @override
  Future<Configuracion> getConfig() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('configuracion', limit: 1);
    if (maps.isNotEmpty) {
      return ConfigModel.fromMap(maps.first);
    }
    return Configuracion(nombreNegocio: 'Sastrería', comisionGeneral: 0.0);
  }

  @override
  Future<void> saveConfig(Configuracion config) async {
    final db = await dbHelper.database;
    await db.update(
      'configuracion',
      ConfigModel(
        nombreNegocio: config.nombreNegocio,
        comisionGeneral: config.comisionGeneral,
      ).toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}
