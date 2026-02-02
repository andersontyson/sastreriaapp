import 'package:flutter_test/flutter_test.dart';
import 'package:sastreria_app/data/datasources/database_helper.dart';
import 'package:sastreria_app/data/repositories/cobro_repository_impl.dart';
import 'package:sastreria_app/data/repositories/config_repository_impl.dart';
import 'package:sastreria_app/data/repositories/sastre_repository_impl.dart';
import 'package:sastreria_app/presentation/providers/shop_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;
  late ShopProvider provider;

  setUp(() async {
    dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    await db.delete('configuracion');
    await db.delete('sastres');
    await db.delete('cobros');

    // Initial config as DatabaseHelper does in version 3
    await db.insert('configuracion', {
      'id': 1,
      'nombreNegocio': 'Mi Sastrería',
      'comisionGeneral': 10.0,
      'isActivated': 0
    });

    provider = ShopProvider(
      sastreRepo: SastreRepositoryImpl(dbHelper),
      cobroRepo: CobroRepositoryImpl(dbHelper),
      configRepo: ConfigRepositoryImpl(dbHelper),
    );
    await provider.loadInitialData();
  });

  group('Activation Module Tests', () {
    test('Should validate activation code correctly', () {
      final fechaHoy = DateFormat('yyyyMMdd').format(DateTime.now());

      expect(provider.validarCodigoActivacion(''), isNotNull);
      expect(provider.validarCodigoActivacion('INVALID'), isNotNull);
      expect(provider.validarCodigoActivacion('SAST-20000101-XXXX'), isNotNull);
      expect(provider.validarCodigoActivacion('SAST-$fechaHoy-XXXX'), isNull);
    });

    test('Should activate system correctly', () async {
      final fechaHoy = DateFormat('yyyyMMdd').format(DateTime.now());
      final codigo = 'SAST-$fechaHoy-1234';

      await provider.activarSistema(
        nombreNegocio: 'Sastrería Guty',
        nombreDueno: 'Guty',
        codigoActivacion: codigo,
      );

      expect(provider.config?.isActivated, isTrue);
      expect(provider.config?.nombreNegocio, 'Sastrería Guty');
      expect(provider.sastres.length, 1);
      expect(provider.sastres.first.nombre, 'Guty');
      expect(provider.sastres.first.esDueno, isTrue);
    });
  });
}
