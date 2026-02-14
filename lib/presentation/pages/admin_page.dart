import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/configuracion.dart';
import '../providers/shop_provider.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _comisionController = TextEditingController();
  final _nombreNegocioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ShopProvider>(context, listen: false);
    _comisionController.text = provider.config?.comisionGeneral.toString() ?? '0';
    _nombreNegocioController.text = provider.config?.nombreNegocio ?? 'Sastrería';
  }

  @override
  void dispose() {
    _comisionController.dispose();
    _nombreNegocioController.dispose();
    super.dispose();
  }

  void _guardarConfig() {
    final provider = Provider.of<ShopProvider>(context, listen: false);
    if (provider.config == null) return;

    final nuevaConfig = provider.config!.copyWith(
      nombreNegocio: _nombreNegocioController.text,
      comisionGeneral: double.tryParse(_comisionController.text) ?? 0,
    );

    provider.updateConfig(nuevaConfig);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ShopProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Administración')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle('Configuración General'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nombreNegocioController,
                    decoration: const InputDecoration(labelText: 'Nombre del Negocio'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _comisionController,
                    decoration: const InputDecoration(labelText: 'Comisión General (%)', suffixText: '%'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _guardarConfig, child: const Text('Guardar Configuración')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Gestión de Sastres'),
          ...provider.sastres.map((sastre) => ListTile(
            title: Text(sastre.nombre + (sastre.esDueno ? ' (Propietario)' : '')),
            subtitle: Text(sastre.estaActivo ? 'Activo' : 'Inactivo'),
            trailing: Switch(
              value: sastre.estaActivo,
              onChanged: sastre.esDueno ? null : (val) => provider.toggleSastreActivo(sastre.id),
            ),
          )),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoNuevoSastre(context, provider),
            icon: const Icon(Icons.person_add),
            label: const Text('Añadir Sastre'),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Reportes Históricos'),
          _buildHistoricalReports(provider),
        ],
      ),
    );
  }

  Widget _buildHistoricalReports(ShopProvider provider) {
    return FutureBuilder(
      future: provider.getAllCobros(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final allCobros = snapshot.data as List;
        final totalComisiones = allCobros.fold(0.0, (sum, c) => sum + c.comisionMonto);
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _reportRow('Total Comisiones Acumuladas:', totalComisiones),
                const Divider(),
                const Text('Monto entregado por sastre (Histórico):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...provider.sastres.map((s) {
                  final entregado = allCobros
                      .where((c) => c.sastreId == s.id)
                      .fold(0.0, (sum, c) => sum + c.netoSastre);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.nombre),
                        Text('RD\$ ${entregado.toStringAsFixed(2)}'),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _reportRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('RD\$ ${value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  void _mostrarDialogoNuevoSastre(BuildContext context, ShopProvider provider) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Sastre'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                provider.addSastre(nameController.text, false, null);
                Navigator.pop(context);
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }
}
