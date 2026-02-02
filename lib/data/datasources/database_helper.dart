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
      version: 3, // Incremented to version 3 for activation fields
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
        comisionGeneral REAL,
        isActivated INTEGER DEFAULT 0,
        activationDate TEXT,
        activationCode TEXT
      )
    ''');

    // Initial config (not activated)
    await db.insert('configuracion', {
      'id': 1,
      'nombreNegocio': 'Mi Sastrería',
      'comisionGeneral': 10.0,
      'isActivated': 0
    });

    // We don't create an initial owner here anymore,
    // it will be created during activation.
    // However, for existing systems, we might need to handle it.
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS sastres');
      await db.execute('DROP TABLE IF EXISTS cobros');
      await db.execute('DROP TABLE IF EXISTS configuracion');
      await _onCreate(db, newVersion);
    } else if (oldVersion == 2) {
      // Add new columns to configuracion for version 3
      await db.execute('ALTER TABLE configuracion ADD COLUMN isActivated INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE configuracion ADD COLUMN activationDate TEXT');
      await db.execute('ALTER TABLE configuracion ADD COLUMN activationCode TEXT');

      // If there are already sastres, we might assume it was "activated" or just let it be.
      // But according to rules, it must show ActivationPage if isActivated is false.
    }
  }
}
