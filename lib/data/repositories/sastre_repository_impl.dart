import '../../domain/entities/sastre.dart';
import '../../domain/repositories/sastre_repository.dart';
import '../datasources/database_helper.dart';

class SastreRepositoryImpl implements SastreRepository {
  final DatabaseHelper dbHelper;

  SastreRepositoryImpl(this.dbHelper);

  @override
  Future<List<Sastre>> getSastres() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('sastres');
    return List.generate(maps.length, (i) => Sastre.fromMap(maps[i]));
  }

  @override
  Future<void> addSastre(Sastre sastre) async {
    final db = await dbHelper.database;
    await db.insert('sastres', sastre.toMap());
  }

  @override
  Future<void> updateSastre(Sastre sastre) async {
    final db = await dbHelper.database;
    await db.update(
      'sastres',
      sastre.toMap(),
      where: 'id = ?',
      whereArgs: [sastre.id],
    );
  }

  @override
  Future<void> deleteSastre(String id) async {
    final db = await dbHelper.database;
    await db.delete('sastres', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Sastre?> getSastreById(String id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sastres',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Sastre.fromMap(maps.first);
    }
    return null;
  }
}
