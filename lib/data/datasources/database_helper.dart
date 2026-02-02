import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

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
      version: 2, // Incremented version for schema changes
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sastres (
        id TEXT PRIMARY KEY,
        nombre TEXT,
        esDueno INTEGER,
        estaActivo INTEGER,
        createdAt TEXT,
        comisionFija REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE cobros (
        id TEXT PRIMARY KEY,
        sastreId TEXT,
        montoTotal REAL,
        comisionPorcentaje REAL,
        comisionMonto REAL,
        netoSastre REAL,
        fecha TEXT,
        esCierre INTEGER,
        cliente TEXT,
        prenda TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE configuracion (
        id INTEGER PRIMARY KEY DEFAULT 1,
        nombreNegocio TEXT,
        comisionGeneral REAL
      )
    ''');

    // Initial config
    await db.insert('configuracion', {
      'id': 1,
      'nombreNegocio': 'Sastrería Profesional',
      'comisionGeneral': 10.0
    });

    // Initial owner
    final now = DateTime.now().toIso8601String();
    await db.insert('sastres', {
      'id': const Uuid().v4(),
      'nombre': 'Juan (Propietario)',
      'esDueno': 1,
      'estaActivo': 1,
      'createdAt': now,
      'comisionFija': 0.0
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Simplest way for this task: drop and recreate
      await db.execute('DROP TABLE IF EXISTS sastres');
      await db.execute('DROP TABLE IF EXISTS cobros');
      await db.execute('DROP TABLE IF EXISTS configuracion');
      await _onCreate(db, newVersion);
    }
  }
}
