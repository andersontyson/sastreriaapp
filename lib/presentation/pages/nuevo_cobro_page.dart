import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import 'package:intl/intl.dart';
import '../../services/printing_service.dart';
import '../../domain/entities/cobro.dart';

class NuevoCobroPage extends StatefulWidget {
  const NuevoCobroPage({super.key});

  @override
  State<NuevoCobroPage> createState() => _NuevoCobroPageState();
}

class _NuevoCobroPageState extends State<NuevoCobroPage> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _clienteController = TextEditingController();
  final _prendaController = TextEditingController();
  
  String? _sastreSeleccionadoId;
  double _comisionCalculada = 0;
  double _netoCalculado = 0;

  @override
  void dispose() {
    _montoController.dispose();
    _clienteController.dispose();
    _prendaController.dispose();
    super.dispose();
  }

  void _actualizarCalculos() {
    if (_sastreSeleccionadoId == null || _montoController.text.isEmpty) {
      setState(() {
        _comisionCalculada = 0;
        _netoCalculado = 0;
      });
      return;
    }

    final provider = Provider.of<ShopProvider>(context, listen: false);
    final sastre = provider.sastres.firstWhere((s) => s.id == _sastreSeleccionadoId);
    final monto = double.tryParse(_montoController.text) ?? 0;

    double porcentaje = 0;
    if (!sastre.esDueno) {
      porcentaje = sastre.comisionFija ?? provider.config?.comisionGeneral ?? 0;
    }

    setState(() {
      _comisionCalculada = (monto * porcentaje) / 100;
      _netoCalculado = monto - _comisionCalculada;
    });
  }

  Future<void> _guardarCobro() async {
    if (!_formKey.currentState!.validate() || _sastreSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un sastre y escribe un monto')),
      );
      return;
    }

    final provider = Provider.of<ShopProvider>(context, listen: false);
    final sastre = provider.sastres.firstWhere((s) => s.id == _sastreSeleccionadoId);
    final monto = double.parse(_montoController.text);
    final cliente = _clienteController.text;
    final prenda = _prendaController.text;

    // Guardar en SQLite
    await provider.addCobro(
      sastreId: _sastreSeleccionadoId!,
      monto: monto,
      cliente: cliente,
      prenda: prenda,
    );

    // Intentar imprimir
    final temporaryCobro = Cobro(
      id: 'temp',
      sastreId: _sastreSeleccionadoId!,
      montoTotal: monto,
      comisionPorcentaje: 0, // No es crítico para la factura impresa según el diseño
      comisionMonto: _comisionCalculada,
      netoSastre: _netoCalculado,
      fecha: DateTime.now(),
      cliente: cliente,
      prenda: prenda,
    );

    final printSuccess = await PrintingService.printInvoice(
      cobro: temporaryCobro,
      sastre: sastre,
      nombreNegocio: provider.config?.nombreNegocio ?? 'Sastrería',
    );

    if (mounted) {
      Navigator.pop(context);
      if (printSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cobro registrado e impreso correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cobro guardado, pero no se pudo imprimir'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ShopProvider>(context);
    final activeSastres = provider.sastres.where((s) => s.estaActivo).toList();
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_DO');

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Cobro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Quién realizó el trabajo?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildSastreSelector(activeSastres),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Monto RD\$',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                onChanged: (_) => _actualizarCalculos(),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (double.tryParse(value) == null) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              if (_sastreSeleccionadoId != null && _montoController.text.isNotEmpty)
                _buildCalculoResumen(currencyFormat),
                
              const SizedBox(height: 24),
              TextFormField(
                controller: _clienteController,
                decoration: const InputDecoration(
                  labelText: 'Cliente (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prendaController,
                decoration: const InputDecoration(
                  labelText: 'Prenda / Detalle (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.checkroom),
                ),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardarCobro,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('COBRAR Y REGISTRAR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSastreSelector(List activeSastres) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: activeSastres.map((s) {
        bool isSelected = _sastreSeleccionadoId == s.id;
        return ChoiceChip(
          label: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(s.nombre, style: TextStyle(fontSize: 18, color: isSelected ? Colors.white : Colors.black87)),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _sastreSeleccionadoId = selected ? s.id : null;
              _actualizarCalculos();
            });
          },
          selectedColor: Colors.blue.shade700,
          backgroundColor: Colors.grey.shade200,
        );
      }).toList(),
    );
  }

  Widget _buildCalculoResumen(NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('Comisión', format.format(_comisionCalculada), Colors.red.shade700),
          _buildInfoItem('Para el Sastre', format.format(_netoCalculado), Colors.green.shade700),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
