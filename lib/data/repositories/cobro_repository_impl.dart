import '../../domain/entities/cobro.dart';
import '../../domain/repositories/cobro_repository.dart';
import '../datasources/database_helper.dart';
import '../models/cobro_model.dart';

class CobroRepositoryImpl implements CobroRepository {
  final DatabaseHelper dbHelper;

  CobroRepositoryImpl(this.dbHelper);

  @override
  Future<List<Cobro>> getCobrosDelDia(DateTime fecha) async {
    final db = await dbHelper.database;
    final String startOfDay = DateTime(fecha.year, fecha.month, fecha.day).toIso8601String();
    final String endOfDay = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'cobros',
      where: 'fechaHora BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
    );

    return List.generate(maps.length, (i) => CobroModel.fromMap(maps[i]));
  }

  @override
  Future<List<Cobro>> getAllCobros() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('cobros');
    return List.generate(maps.length, (i) => CobroModel.fromMap(maps[i]));
  }

  @override
  Future<void> addCobro(Cobro cobro) async {
    final db = await dbHelper.database;
    await db.insert('cobros', CobroModel(
      id: cobro.id,
      sastreId: cobro.sastreId,
      monto: cobro.monto,
      cliente: cobro.cliente,
      prenda: cobro.prenda,
      fechaHora: cobro.fechaHora,
      comisionMonto: cobro.comisionMonto,
      netoSastre: cobro.netoSastre,
    ).toMap());
  }

  @override
  Future<void> deleteCobro(String id) async {
    final db = await dbHelper.database;
    await db.delete('cobros', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clearCobrosDelDia(DateTime fecha) async {
    final db = await dbHelper.database;
    final String startOfDay = DateTime(fecha.year, fecha.month, fecha.day).toIso8601String();
    final String endOfDay = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59).toIso8601String();

    await db.delete(
      'cobros',
      where: 'fechaHora BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
    );
  }
}
