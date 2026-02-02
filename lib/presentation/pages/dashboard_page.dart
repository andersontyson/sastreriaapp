import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ShopProvider>(context);
    final currencyFormat = NumberFormat.currency(
  locale: 'es_DO',
  symbol: 'RD\$',
  decimalDigits: 2,
);


    return Scaffold(
      appBar: AppBar(
        title: Text(provider.config?.nombreNegocio ?? 'Sastrería'),
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/admin'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMainStats(provider, currencyFormat),
            const SizedBox(height: 24),
            const Text(
              'Resumen por Sastre',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSastresGrid(provider, currencyFormat),
            const SizedBox(height: 32),
            _buildActionButtons(context),
            const SizedBox(height: 24),
            _buildReportButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/reportes'),
        icon: const Icon(Icons.history_outlined),
        label: const Text('Ver Reportes Históricos'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.orange.shade800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildMainStats(ShopProvider provider, NumberFormat format) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Total Cobrado Hoy (Clientes)', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              format.format(provider.totalCobradoHoy),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSastresGrid(ShopProvider provider, NumberFormat format) {
    final activeSastres = provider.sastres.where((s) => s.estaActivo).toList();
    
    return LayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: activeSastres.length,
        itemBuilder: (context, index) {
          final sastre = activeSastres[index];
          double monto = provider.getNetoSastreHoy(sastre.id);
          if (sastre.esDueno) {
            monto += provider.totalComisionesHoy;
          }

          return Card(
            elevation: 1,
            color: sastre.esDueno ? Colors.blue.shade50 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(sastre.esDueno ? Icons.person_pin : Icons.person, size: 20, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        sastre.nombre, 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    format.format(monto),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: sastre.esDueno ? Colors.blue.shade800 : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/nuevo-cobro'),
                icon: const Icon(Icons.add, size: 30),
                label: const Text('Nuevo Cobro', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/cierre'),
                icon: const Icon(Icons.analytics, size: 30),
                label: const Text('Cierre del Día', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/lista-cobros'),
            icon: const Icon(Icons.list_alt),
            label: const Text('Ver lista de cobros del día', style: TextStyle(fontSize: 18)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.blue.shade700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
