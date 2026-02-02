import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import 'package:intl/intl.dart';

class CierrePage extends StatelessWidget {
  const CierrePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ShopProvider>(context);
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_DO');

    return Scaffold(
      appBar: AppBar(title: const Text('Cierre del Día')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...provider.sastres.where((s) => s.estaActivo).map((sastre) {
              final generado = provider.cobrosHoy
                  .where((c) => c.sastreId == sastre.id)
                  .fold(0.0, (sum, c) => sum + c.monto);
              final comision = provider.cobrosHoy
                  .where((c) => c.sastreId == sastre.id)
                  .fold(0.0, (sum, c) => sum + c.comisionMonto);
              final neto = generado - comision;

              return _buildSastreSummary(sastre.nombre, generado, comision, neto, currencyFormat);
            }),
            const SizedBox(height: 24),
            _buildPropietarioSummary(provider, currencyFormat),
            const SizedBox(height: 40),
            _buildCerrarDiaButton(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildSastreSummary(String nombre, double total, double comision, double neto, NumberFormat format) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _summaryRow('Total trabajos:', format.format(total)),
            if (comision > 0)
              _summaryRow('Comisión descontada:', '- ${format.format(comision)}', color: Colors.red),
            const SizedBox(height: 8),
            _summaryRow('Monto a entregar:', format.format(neto), color: Colors.green, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPropietarioSummary(ShopProvider provider, NumberFormat format) {
    final dueno = provider.sastres.firstWhere((s) => s.esDueno);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Text('Resumen Propietario (${dueno.nombre})', 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 12),
          Text(
            'Comisión Total del Día: ${format.format(provider.totalComisionesHoy)}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(
            fontSize: 18, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color
          )),
        ],
      ),
    );
  }

  Widget _buildCerrarDiaButton(BuildContext context, ShopProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _confirmarCierre(context, provider),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(20),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('CERRAR DÍA Y REINICIAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _confirmarCierre(BuildContext context, ShopProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar el día?'),
        content: const Text('Esto reiniciará todos los contadores de hoy. Asegúrate de haber entregado el dinero.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await provider.resetDay();
              if (context.mounted) {
                Navigator.popUntil(context, ModalRoute.withName('/'));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Día cerrado correctamente')));
              }
            },
            child: const Text('Cerrar Día', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
