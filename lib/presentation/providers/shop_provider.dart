import 'package:flutter/material.dart';
import '../../domain/entities/cobro.dart';
import '../../domain/entities/configuracion.dart';
import '../../domain/entities/sastre.dart';
import '../../domain/repositories/cobro_repository.dart';
import '../../domain/repositories/config_repository.dart';
import '../../domain/repositories/sastre_repository.dart';
import 'package:uuid/uuid.dart';

class ShopProvider with ChangeNotifier {
  final SastreRepository sastreRepo;
  final CobroRepository cobroRepo;
  final ConfigRepository configRepo;

  List<Sastre> _sastres = [];
  List<Cobro> _cobrosHoy = [];
  Configuracion? _config;

  ShopProvider({
    required this.sastreRepo,
    required this.cobroRepo,
    required this.configRepo,
  });

  List<Sastre> get sastres => _sastres;
  List<Cobro> get cobrosHoy => _cobrosHoy;
  Configuracion? get config => _config;

  Future<void> loadInitialData() async {
    _config = await configRepo.getConfig();
    _sastres = await sastreRepo.getSastres();
    _cobrosHoy = await cobroRepo.getCobrosDelDia(DateTime.now());
    notifyListeners();
  }

  double get totalCobradoHoy {
    return _cobrosHoy.fold(0, (sum, item) => sum + item.monto);
  }

  double get totalComisionesHoy {
    return _cobrosHoy.fold(0, (sum, item) => sum + item.comisionMonto);
  }

  double getNetoSastre(String sastreId) {
    return _cobrosHoy
        .where((c) => c.sastreId == sastreId)
        .fold(0, (sum, item) => sum + item.netoSastre);
  }

  Future<void> addCobro({
    required String sastreId,
    required double monto,
    String? cliente,
    String? prenda,
  }) async {
    final sastre = _sastres.firstWhere((s) => s.id == sastreId);
    // Si el sastre es dueño, la comisión es 0 (él se lleva todo o su parte neta es el total)
    // Pero según el HTML, el dueño recibe comisión de otros.
    // Si el dueño hace un trabajo, ¿se descuenta comisión a sí mismo?
    // En el HTML: $('total-juan').textContent = formatearDinero(acumNeto.Juan + totalComision);
    // Así que el dueño recibe su neto + todas las comisiones.
    
    double comisionPorcentaje = 0;
    if (!sastre.esDueno) {
      comisionPorcentaje = sastre.comisionFija ?? _config?.comisionGeneral ?? 0.0;
    }
    
    final double comisionMonto = (monto * comisionPorcentaje) / 100;
    final double netoSastre = monto - comisionMonto;

    final nuevoCobro = Cobro(
      id: const Uuid().v4(),
      sastreId: sastreId,
      monto: monto,
      cliente: cliente,
      prenda: prenda,
      fechaHora: DateTime.now(),
      comisionMonto: comisionMonto,
      netoSastre: netoSastre,
    );

    await cobroRepo.addCobro(nuevoCobro);
    _cobrosHoy = await cobroRepo.getCobrosDelDia(DateTime.now());
    notifyListeners();
  }

  Future<void> deleteCobro(String id) async {
    await cobroRepo.deleteCobro(id);
    _cobrosHoy = await cobroRepo.getCobrosDelDia(DateTime.now());
    notifyListeners();
  }

  Future<void> resetDay() async {
    await cobroRepo.clearCobrosDelDia(DateTime.now());
    _cobrosHoy = [];
    notifyListeners();
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
    );
    await sastreRepo.addSastre(sastre);
    _sastres = await sastreRepo.getSastres();
    notifyListeners();
  }

  Future<List<Cobro>> getAllCobros() async {
    return await cobroRepo.getAllCobros();
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
      );
      await sastreRepo.updateSastre(updated);
      _sastres = await sastreRepo.getSastres();
      notifyListeners();
    }
  }
}
