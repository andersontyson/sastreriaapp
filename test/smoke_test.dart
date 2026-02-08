import 'package:flutter_test/flutter_test.dart';
import 'package:sastreria_app/main.dart';
import 'package:provider/provider.dart';
import 'package:sastreria_app/presentation/providers/shop_provider.dart';
import 'package:sastreria_app/data/datasources/database_helper.dart';
import 'package:sastreria_app/data/repositories/sastre_repository_impl.dart';
import 'package:sastreria_app/data/repositories/cobro_repository_impl.dart';
import 'package:sastreria_app/data/repositories/config_repository_impl.dart';
import 'package:sastreria_app/services/printing_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockPrintingService extends PrintingService {
  @override
  Future<bool> printInvoice({required config, required sastre, required cobro}) async {
    return true;
  }
}

void main() {
  // Initialize sqflite_ffi for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    final dbHelper = DatabaseHelper();
    final sastreRepo = SastreRepositoryImpl(dbHelper);
    final cobroRepo = CobroRepositoryImpl(dbHelper);
    final configRepo = ConfigRepositoryImpl(dbHelper);

    final shopProvider = ShopProvider(
      sastreRepo: sastreRepo,
      cobroRepo: cobroRepo,
      configRepo: configRepo,
      printingService: MockPrintingService(),
    );

    await shopProvider.loadInitialData();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => shopProvider,
        child: const MyApp(),
      ),
    );

    // Verify Dashboard shows up
    expect(find.text('Nuevo Cobro'), findsOneWidget);
    expect(find.text('Cierre del Día'), findsOneWidget);
  });
}
