import '../../domain/entities/sastre.dart';
import '../../domain/repositories/sastre_repository.dart';
import '../datasources/database_helper.dart';
import '../models/sastre_model.dart';

class SastreRepositoryImpl implements SastreRepository {
  final DatabaseHelper dbHelper;

  SastreRepositoryImpl(this.dbHelper);

  @override
  Future<List<Sastre>> getSastres() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('sastres');
    return List.generate(maps.length, (i) => SastreModel.fromMap(maps[i]));
  }

  @override
  Future<void> addSastre(Sastre sastre) async {
    final db = await dbHelper.database;
    await db.insert('sastres', SastreModel(
      id: sastre.id,
      nombre: sastre.nombre,
      esDueno: sastre.esDueno,
      comisionFija: sastre.comisionFija,
      estaActivo: sastre.estaActivo,
    ).toMap());
  }

  @override
  Future<void> updateSastre(Sastre sastre) async {
    final db = await dbHelper.database;
    await db.update(
      'sastres',
      SastreModel(
        id: sastre.id,
        nombre: sastre.nombre,
        esDueno: sastre.esDueno,
        comisionFija: sastre.comisionFija,
        estaActivo: sastre.estaActivo,
      ).toMap(),
      where: 'id = ?',
      whereArgs: [sastre.id],
    );
  }

  @override
  Future<void> deleteSastre(String id) async {
    final db = await dbHelper.database;
    await db.delete('sastres', where: 'id = ?', whereArgs: [id]);
  }
}
