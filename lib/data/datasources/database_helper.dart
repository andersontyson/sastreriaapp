import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sastreria.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sastres (
        id TEXT PRIMARY KEY,
        nombre TEXT,
        esDueno INTEGER,
        comisionFija REAL,
        estaActivo INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE cobros (
        id TEXT PRIMARY KEY,
        sastreId TEXT,
        monto REAL,
        cliente TEXT,
        prenda TEXT,
        fechaHora TEXT,
        comisionMonto REAL,
        netoSastre REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE configuracion (
        id INTEGER PRIMARY KEY DEFAULT 1,
        nombreNegocio TEXT,
        comisionGeneral REAL
      )
    ''');

    // Initial config and default owner
    await db.insert('configuracion', {
      'nombreNegocio': 'Sastrería Demo',
      'comisionGeneral': 0.0
    });

    await db.insert('sastres', {
      'id': 'juan-propietario',
      'nombre': 'Juan (Propietario)',
      'esDueno': 1,
      'comisionFija': null,
      'estaActivo': 1
    });
  }
}
