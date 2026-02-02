import '../../domain/entities/cobro.dart';
import '../../domain/repositories/cobro_repository.dart';
import '../datasources/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class CobroRepositoryImpl implements CobroRepository {
  final DatabaseHelper dbHelper;

  CobroRepositoryImpl(this.dbHelper);

  @override
  Future<List<Cobro>> getCobrosDelDia(DateTime fecha) async {
    final db = await dbHelper.database;
    final String dateStr = fecha.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'cobros',
      where: "fecha LIKE ?",
      whereArgs: ['$dateStr%'],
    );
    return List.generate(maps.length, (i) => Cobro.fromMap(maps[i]));
  }

  @override
  Future<List<Cobro>> getAllCobros() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('cobros', orderBy: 'fecha DESC');
    return List.generate(maps.length, (i) => Cobro.fromMap(maps[i]));
  }

  @override
  Future<List<Cobro>> getCobrosPorRango(DateTime inicio, DateTime fin) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cobros',
      where: "fecha BETWEEN ? AND ?",
      whereArgs: [inicio.toIso8601String(), fin.toIso8601String()],
      orderBy: 'fecha DESC',
    );
    return List.generate(maps.length, (i) => Cobro.fromMap(maps[i]));
  }

  @override
  Future<void> addCobro(Cobro cobro) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('cobros', cobro.toMap());
    });
  }

  @override
  Future<void> deleteCobro(String id) async {
    final db = await dbHelper.database;
    await db.delete('cobros', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> marcarCierreDelDia(DateTime fecha) async {
    final db = await dbHelper.database;
    final String dateStr = fecha.toIso8601String().split('T')[0];
    await db.update(
      'cobros',
      {'esCierre': 1},
      where: "fecha LIKE ? AND esCierre = 0",
      whereArgs: ['$dateStr%'],
    );
  }

  @override
  Future<double> getTotalPorDia(DateTime fecha) async {
    final db = await dbHelper.database;
    final String dateStr = fecha.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(montoTotal) as total FROM cobros WHERE fecha LIKE ?',
      ['$dateStr%']
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<Map<String, double>> getTotalPorSastre(DateTime inicio, DateTime fin) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''SELECT sastreId, SUM(montoTotal) as total
         FROM cobros
         WHERE fecha BETWEEN ? AND ?
         GROUP BY sastreId''',
      [inicio.toIso8601String(), fin.toIso8601String()]
    );

    final Map<String, double> totals = {};
    for (var row in result) {
      totals[row['sastreId'] as String] = (row['total'] as num).toDouble();
    }
    return totals;
  }

  @override
  Future<double> getTotalHistorico() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT SUM(montoTotal) as total FROM cobros');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<double> getComisionesAcumuladas(DateTime inicio, DateTime fin) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(comisionMonto) as total FROM cobros WHERE fecha BETWEEN ? AND ?',
      [inicio.toIso8601String(), fin.toIso8601String()]
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
