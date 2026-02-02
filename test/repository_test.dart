import 'package:flutter_test/flutter_test.dart';
import 'package:sastreria_app/data/datasources/database_helper.dart';
import 'package:sastreria_app/data/repositories/cobro_repository_impl.dart';
import 'package:sastreria_app/data/repositories/sastre_repository_impl.dart';
import 'package:sastreria_app/domain/entities/cobro.dart';
import 'package:sastreria_app/domain/entities/sastre.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

void main() {
  // Initialize sqflite_ffi for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;
  late CobroRepositoryImpl cobroRepo;
  late SastreRepositoryImpl sastreRepo;

  setUp(() async {
    dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    await db.delete('cobros');
    await db.delete('sastres');

    cobroRepo = CobroRepositoryImpl(dbHelper);
    sastreRepo = SastreRepositoryImpl(dbHelper);
  });

  test('Should add and retrieve a sastre', () async {
    final sastre = Sastre(
      id: const Uuid().v4(),
      nombre: 'Test Sastre',
      esDueno: false,
      createdAt: DateTime.now(),
    );

    await sastreRepo.addSastre(sastre);
    final sastres = await sastreRepo.getSastres();

    expect(sastres.any((s) => s.id == sastre.id), isTrue);
  });

  test('Should add a cobro and calculate daily total', () async {
    final sastreId = const Uuid().v4();
    final now = DateTime.now();
    final cobro = Cobro(
      id: const Uuid().v4(),
      sastreId: sastreId,
      montoTotal: 1000.0,
      comisionPorcentaje: 10.0,
      comisionMonto: 100.0,
      netoSastre: 900.0,
      fecha: now,
    );

    await cobroRepo.addCobro(cobro);
    final total = await cobroRepo.getTotalPorDia(now);

    expect(total, 1000.0);
  });

  test('Should calculate aggregated totals correctly', () async {
    final s1 = const Uuid().v4();
    final s2 = const Uuid().v4();
    final now = DateTime.now();

    final c1 = Cobro(id: '1', sastreId: s1, montoTotal: 500, comisionPorcentaje: 10, comisionMonto: 50, netoSastre: 450, fecha: now);
    final c2 = Cobro(id: '2', sastreId: s2, montoTotal: 300, comisionPorcentaje: 10, comisionMonto: 30, netoSastre: 270, fecha: now);

    await cobroRepo.addCobro(c1);
    await cobroRepo.addCobro(c2);

    final historicalTotal = await cobroRepo.getTotalHistorico();
    final comisiones = await cobroRepo.getComisionesAcumuladas(
      now.subtract(const Duration(days: 1)),
      now.add(const Duration(days: 1))
    );

    expect(historicalTotal, greaterThanOrEqualTo(800.0));
    expect(comisiones, greaterThanOrEqualTo(80.0));
  });
}
