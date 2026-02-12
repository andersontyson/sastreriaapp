import 'package:flutter_test/flutter_test.dart';
import 'package:sastreria_app/data/datasources/database_helper.dart';
import 'package:sastreria_app/data/repositories/cobro_repository_impl.dart';
import 'package:sastreria_app/data/repositories/config_repository_impl.dart';
import 'package:sastreria_app/data/repositories/sastre_repository_impl.dart';
import 'package:sastreria_app/domain/entities/cobro.dart';
import 'package:sastreria_app/presentation/providers/shop_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;
  late ShopProvider provider;

  setUp(() async {
    dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    await db.delete('cobros');
    await db.delete('sastres');
    await db.delete('configuracion');

    // Re-insert initial config for version 4
    await db.insert('configuracion', {
      'id': 1,
      'nombreNegocio': 'Test Shop',
      'comisionGeneral': 10.0,
      'isActivated': 1,
      'businessDate': null,
    });

    provider = ShopProvider(
      sastreRepo: SastreRepositoryImpl(dbHelper),
      cobroRepo: CobroRepositoryImpl(dbHelper),
      configRepo: ConfigRepositoryImpl(dbHelper),
    );
  });

  test('Should initialize businessDate on first load', () async {
    await provider.loadInitialData();
    expect(provider.config?.businessDate, isNotNull);
    final now = DateTime.now();
    expect(provider.config?.businessDate?.year, now.year);
    expect(provider.config?.businessDate?.month, now.month);
    expect(provider.config?.businessDate?.day, now.day);
  });

  test('Should advance businessDate on closure and clear today list', () async {
    await provider.loadInitialData();
    final initialDate = provider.config!.businessDate!;

    // Add a sastre and a cobro for "today"
    await provider.addSastre('Sastre 1', false, 10.0);
    final sastreId = provider.sastres.first.id;

    // Manually add a cobro with the current business date to ensure it matches
    final cobro = Cobro(
      id: 'c1',
      sastreId: sastreId,
      montoTotal: 1000,
      comisionPorcentaje: 10,
      comisionMonto: 100,
      netoSastre: 900,
      fecha: initialDate,
    );
    await provider.cobroRepo.addCobro(cobro);
    await provider.loadCobrosHoy();

    expect(provider.cobrosHoy.length, 1);

    // Close day
    await provider.cerrarDia(print: false);

    expect(provider.config!.businessDate, initialDate.add(const Duration(days: 1)));
    expect(provider.cobrosHoy.length, 0); // Should be empty for the new day

    // Historical data should still exist
    final allCobros = await provider.getAllCobros();
    expect(allCobros.length, 1);
    expect(allCobros.first.esCierre, isTrue);
  });
}
