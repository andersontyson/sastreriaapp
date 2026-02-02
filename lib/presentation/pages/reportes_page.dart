import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../../domain/entities/cobro.dart';
import '../../domain/entities/sastre.dart';
import 'package:intl/intl.dart';

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 7));
  DateTime _fechaFin = DateTime.now();
  List<Cobro> _reporteCobros = [];
  Map<String, double> _totalesPorSastre = {};
  double _totalCobrado = 0;
  double _totalComisiones = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => _cargarReporte());
  }

  Future<void> _cargarReporte() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final provider = Provider.of<ShopProvider>(context, listen: false);

    final inicio = DateTime(_fechaInicio.year, _fechaInicio.month, _fechaInicio.day, 0, 0, 0);
    final fin = DateTime(_fechaFin.year, _fechaFin.month, _fechaFin.day, 23, 59, 59);

    final cobros = await provider.getCobrosPorRango(inicio, fin);
    final totalesSastre = await provider.getTotalesPorSastre(inicio, fin);
    final comisiones = await provider.getComisionesAcumuladas(inicio, fin);

    double total = 0;
    for (var c in cobros) {
      total += c.montoTotal;
    }

    if (!mounted) return;
    setState(() {
      _reporteCobros = cobros;
      _totalesPorSastre = totalesSastre;
      _totalCobrado = total;
      _totalComisiones = comisiones;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_DO');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Históricos'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Column(
        children: [
          _buildFiltros(dateFormat),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildResumenGeneral(currencyFormat),
                    const SizedBox(height: 24),
                    const Text('Desglose por Sastre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildDesgloseSastres(currencyFormat),
                    const SizedBox(height: 24),
                    const Text('Listado de Cobros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildListaCobros(currencyFormat, dateFormat),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltros(DateFormat format) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fechaInicio,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _fechaInicio = picked);
                  _cargarReporte();
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Desde', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(format.format(_fechaInicio), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fechaFin,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _fechaFin = picked);
                  _cargarReporte();
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Hasta', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(format.format(_fechaFin), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarReporte,
          )
        ],
      ),
    );
  }

  Widget _buildResumenGeneral(NumberFormat format) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Total Cobrado', format.format(_totalCobrado), Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Comisiones', format.format(_totalComisiones), Colors.orange),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildDesgloseSastres(NumberFormat format) {
    final provider = Provider.of<ShopProvider>(context);
    if (_totalesPorSastre.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No hay datos en este rango')));
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _totalesPorSastre.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final sastreId = _totalesPorSastre.keys.elementAt(index);
          final monto = _totalesPorSastre[sastreId]!;
          final sastre = provider.sastres.firstWhere(
            (s) => s.id == sastreId,
            orElse: () => Sastre(id: sastreId, nombre: 'Sastre Eliminado', esDueno: false, createdAt: DateTime.now())
          );

          return ListTile(
            title: Text(sastre.nombre),
            trailing: Text(format.format(monto), style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  Widget _buildListaCobros(NumberFormat format, DateFormat dateFormat) {
    if (_reporteCobros.isEmpty) {
      return const Center(child: Text('No hay cobros registrados'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reporteCobros.length,
      itemBuilder: (context, index) {
        final cobro = _reporteCobros[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
            title: Text(cobro.cliente ?? 'Sin cliente'),
            subtitle: Text('${dateFormat.format(cobro.fecha)} - ${cobro.prenda ?? "Sin detalle"}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(format.format(cobro.montoTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Neto: ${format.format(cobro.netoSastre)}', style: const TextStyle(fontSize: 11, color: Colors.green)),
              ],
            ),
          ),
        );
      },
    );
  }
}
