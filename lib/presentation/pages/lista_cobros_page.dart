import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/sastre.dart';
import '../providers/shop_provider.dart';
import 'package:intl/intl.dart';

class ListaCobrosPage extends StatelessWidget {
  const ListaCobrosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ShopProvider>(context);
   final currencyFormat = NumberFormat.currency(
  locale: 'es_DO',
  symbol: 'RD\$',
  decimalDigits: 2,
);

    final timeFormat = DateFormat.jm('es_DO');

    return Scaffold(
      appBar: AppBar(title: const Text('Cobros del Día')),
      body: provider.cobrosHoy.isEmpty
          ? const Center(child: Text('No hay cobros registrados hoy.'))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Hora')),
                    DataColumn(label: Text('Sastre')),
                    DataColumn(label: Text('Monto')),
                    DataColumn(label: Text('Comisión')),
                    DataColumn(label: Text('Neto')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: provider.cobrosHoy.reversed.map((cobro) {
                    final sastre = provider.sastres.firstWhere(
                      (s) => s.id == cobro.sastreId,
                      orElse: () => Sastre(id: '', nombre: 'Eliminado', esDueno: false, createdAt: DateTime.now())
                    );
                    return DataRow(cells: [
                      DataCell(Text(timeFormat.format(cobro.fecha))),
                      DataCell(Text(sastre.nombre)),
                      DataCell(Text(currencyFormat.format(cobro.montoTotal))),
                      DataCell(Text(currencyFormat.format(cobro.comisionMonto), style: const TextStyle(color: Colors.red))),
                      DataCell(Text(currencyFormat.format(cobro.netoSastre), style: const TextStyle(color: Colors.green))),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmarEliminacion(context, provider, cobro.id),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
    );
  }

  void _confirmarEliminacion(BuildContext context, ShopProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar cobro?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              provider.deleteCobro(id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
