import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/datasources/database_helper.dart';
import 'data/repositories/cobro_repository_impl.dart';
import 'data/repositories/config_repository_impl.dart';
import 'data/repositories/sastre_repository_impl.dart';
import 'presentation/providers/shop_provider.dart';
import 'presentation/pages/dashboard_page.dart';
// Temporary placeholders for other pages to avoid compilation errors
import 'presentation/pages/nuevo_cobro_page.dart';
import 'presentation/pages/lista_cobros_page.dart';
import 'presentation/pages/cierre_page.dart';
import 'presentation/pages/admin_page.dart';
import 'presentation/pages/reportes_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_DO', null);
  
  final dbHelper = DatabaseHelper();
  final sastreRepo = SastreRepositoryImpl(dbHelper);
  final cobroRepo = CobroRepositoryImpl(dbHelper);
  final configRepo = ConfigRepositoryImpl(dbHelper);

  final shopProvider = ShopProvider(
    sastreRepo: sastreRepo,
    cobroRepo: cobroRepo,
    configRepo: configRepo,
  );

  await shopProvider.loadInitialData();

  runApp(
    ChangeNotifierProvider(
      create: (_) => shopProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sastrería App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardPage(),
        '/nuevo-cobro': (context) => const NuevoCobroPage(),
        '/lista-cobros': (context) => const ListaCobrosPage(),
        '/cierre': (context) => const CierrePage(),
        '/admin': (context) => const AdminPage(),
        '/reportes': (context) => const ReportesPage(),
      },
    );
  }
}
