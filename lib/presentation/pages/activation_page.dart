import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';

class ActivationPage extends StatefulWidget {
  const ActivationPage({super.key});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreNegocioController = TextEditingController();
  final _nombreDuenoController = TextEditingController();
  final _codigoController = TextEditingController();
  bool _isWorking = false;

  @override
  void dispose() {
    _nombreNegocioController.dispose();
    _nombreDuenoController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _intentarActivacion() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ShopProvider>(context, listen: false);

    // Validar código
    final errorCodigo = provider.validarCodigoActivacion(_codigoController.text);
    if (errorCodigo != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorCodigo), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isWorking = true);

    try {
      await provider.activarSistema(
        nombreNegocio: _nombreNegocioController.text,
        nombreDueno: _nombreDuenoController.text,
        codigoActivacion: _codigoController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error durante la activación: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.lock_person_outlined, size: 80, color: Colors.blue),
                      const SizedBox(height: 24),
                      const Text(
                        'Activación del Sistema',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Por favor, complete los datos para iniciar la aplicación por primera vez.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 40),

                      TextFormField(
                        controller: _nombreNegocioController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la Sastrería',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        style: const TextStyle(fontSize: 18),
                        validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _nombreDuenoController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Dueño / Propietario',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        style: const TextStyle(fontSize: 18),
                        validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _codigoController,
                        decoration: const InputDecoration(
                          labelText: 'Código de Activación',
                          hintText: 'SAST-yyyyMMdd-XXXX',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.key),
                        ),
                        style: const TextStyle(fontSize: 18),
                        validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 40),

                      ElevatedButton(
                        onPressed: _isWorking ? null : _intentarActivacion,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isWorking
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('ACTIVAR SISTEMA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
