import 'package:flutter/material.dart';
import '../../domain/entities/cobro.dart';
import '../../domain/entities/configuracion.dart';
import '../../domain/entities/sastre.dart';
import '../../domain/repositories/cobro_repository.dart';
import '../../domain/repositories/config_repository.dart';
import '../../domain/repositories/sastre_repository.dart';
import '../../services/printing_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class ShopProvider with ChangeNotifier {
  final SastreRepository sastreRepo;
  final CobroRepository cobroRepo;
  final ConfigRepository configRepo;
  final PrintingService printingService;

  List<Sastre> _sastres = [];
  List<Cobro> _cobrosHoy = [];
  Configuracion? _config;

  ShopProvider({
    required this.sastreRepo,
    required this.cobroRepo,
    required this.configRepo,
    required this.printingService,
  });

  List<Sastre> get sastres => _sastres;
  List<Cobro> get cobrosHoy => _cobrosHoy;
  Configuracion? get config => _config;

  Future<void> loadInitialData() async {
    _config = await configRepo.getConfig();
    await loadSastres();
    await loadCobrosHoy();
    notifyListeners();
  }

  Future<void> loadSastres() async {
    _sastres = await sastreRepo.getSastres();
    notifyListeners();
  }

  Future<void> loadCobrosHoy() async {
    _cobrosHoy = await cobroRepo.getCobrosDelDia(DateTime.now());
    notifyListeners();
  }

  double get totalCobradoHoy {
    return _cobrosHoy.fold(0, (sum, item) => sum + item.montoTotal);
  }

  double get totalComisionesHoy {
    return _cobrosHoy.fold(0, (sum, item) => sum + item.comisionMonto);
  }

  double getNetoSastreHoy(String sastreId) {
    return _cobrosHoy
        .where((c) => c.sastreId == sastreId)
        .fold(0, (sum, item) => sum + item.netoSastre);
  }

  /// Creates a new payment and optionally prints a receipt.
  /// Returns true if printing was successful (or not requested),
  /// false if printing failed.
  Future<bool> crearCobro({
    required String sastreId,
    required double monto,
    String? cliente,
    String? prenda,
    bool imprimir = false,
  }) async {
    final sastre = _sastres.firstWhere((s) => s.id == sastreId);
    
    double comisionPorcentaje = 0;
    if (!sastre.esDueno) {
      comisionPorcentaje = sastre.comisionFija ?? _config?.comisionGeneral ?? 0.0;
    }
    
    final double comisionMonto = (monto * comisionPorcentaje) / 100;
    final double netoSastre = monto - comisionMonto;

    final nuevoCobro = Cobro(
      id: const Uuid().v4(),
      sastreId: sastreId,
      montoTotal: monto,
      comisionPorcentaje: comisionPorcentaje,
      comisionMonto: comisionMonto,
      netoSastre: netoSastre,
      fecha: DateTime.now(),
      esCierre: false,
      cliente: cliente,
      prenda: prenda,
    );

    await cobroRepo.addCobro(nuevoCobro);
    await loadCobrosHoy();

    if (imprimir && _config != null && sastre.estaActivo) {
      return await printingService.printInvoice(
        config: _config!,
        sastre: sastre,
        cobro: nuevoCobro,
      );
    }
    return true;
  }

  // Alias for backward compatibility or UI convenience
  Future<bool> addCobro({
    required String sastreId,
    required double monto,
    String? cliente,
    String? prenda,
    bool imprimir = false,
  }) async {
    return await crearCobro(
      sastreId: sastreId,
      monto: monto,
      cliente: cliente,
      prenda: prenda,
      imprimir: imprimir,
    );
  }

  Future<void> deleteCobro(String id) async {
    await cobroRepo.deleteCobro(id);
    await loadCobrosHoy();
  }

  Future<void> cerrarDia() async {
    await cobroRepo.marcarCierreDelDia(DateTime.now());
    await loadCobrosHoy();
  }

  // Alias for UI
  Future<void> resetDay() async {
    await cerrarDia();
  }

  Future<void> updateConfig(Configuracion newConfig) async {
    await configRepo.saveConfig(newConfig);
    _config = newConfig;
    notifyListeners();
  }

  Future<void> addSastre(String nombre, bool esDueno, double? comision) async {
    final sastre = Sastre(
      id: const Uuid().v4(),
      nombre: nombre,
      esDueno: esDueno,
      comisionFija: comision,
      createdAt: DateTime.now(),
      estaActivo: true,
    );
    await sastreRepo.addSastre(sastre);
    await loadSastres();
  }

  Future<void> toggleSastreActivo(String id) async {
    final index = _sastres.indexWhere((s) => s.id == id);
    if (index != -1) {
      final s = _sastres[index];
      final updated = Sastre(
        id: s.id,
        nombre: s.nombre,
        esDueno: s.esDueno,
        comisionFija: s.comisionFija,
        estaActivo: !s.estaActivo,
        createdAt: s.createdAt,
      );
      await sastreRepo.updateSastre(updated);
      await loadSastres();
    }
  }

  // Report methods
  Future<double> getTotalesPorFecha(DateTime fecha) async {
    return await cobroRepo.getTotalPorDia(fecha);
  }

  Future<Map<String, double>> getTotalesPorSastre(DateTime inicio, DateTime fin) async {
    return await cobroRepo.getTotalPorSastre(inicio, fin);
  }

  Future<double> getTotalesHistoricos() async {
    return await cobroRepo.getTotalHistorico();
  }

  Future<double> getComisionesAcumuladas(DateTime inicio, DateTime fin) async {
    return await cobroRepo.getComisionesAcumuladas(inicio, fin);
  }

  Future<List<Cobro>> getCobrosPorRango(DateTime inicio, DateTime fin) async {
    return await cobroRepo.getCobrosPorRango(inicio, fin);
  }

  Future<List<Cobro>> getAllCobros() async {
    return await cobroRepo.getAllCobros();
  }

  // --- ACTIVATION MODULE ---

  String? validarCodigoActivacion(String codigo) {
    if (codigo.isEmpty) return 'El código es obligatorio';

    // Format: SAST-yyyyMMdd-XXXX
    final regex = RegExp(r'^SAST-(\d{8})-.+$');
    final match = regex.firstMatch(codigo);

    if (match == null) return 'Formato de código inválido (SAST-yyyyMMdd-XXXX)';

    final fechaCodigoStr = match.group(1)!;
    final fechaActualStr = DateFormat('yyyyMMdd').format(DateTime.now());

    if (fechaCodigoStr != fechaActualStr) {
      return 'La fecha del código no coincide con la fecha actual';
    }

    return null;
  }

  Future<void> activarSistema({
    required String nombreNegocio,
    required String nombreDueno,
    required String codigoActivacion,
  }) async {
    // 1. Create Owner Sastre
    final owner = Sastre(
      id: const Uuid().v4(),
      nombre: nombreDueno,
      esDueno: true,
      estaActivo: true,
      createdAt: DateTime.now(),
      comisionFija: 0.0,
    );
    await sastreRepo.addSastre(owner);

    // 2. Update Configuration
    final updatedConfig = (_config ?? Configuracion(nombreNegocio: nombreNegocio, comisionGeneral: 10.0)).copyWith(
      nombreNegocio: nombreNegocio,
      isActivated: true,
      activationDate: DateTime.now(),
      activationCode: codigoActivacion,
    );

    await configRepo.saveConfig(updatedConfig);
    _config = updatedConfig;

    await loadSastres();
    notifyListeners();
  }
}
