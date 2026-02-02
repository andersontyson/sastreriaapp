import '../entities/cobro.dart';

abstract class CobroRepository {
  Future<List<Cobro>> getCobrosDelDia(DateTime fecha);
  Future<List<Cobro>> getAllCobros();
  Future<List<Cobro>> getCobrosPorRango(DateTime inicio, DateTime fin);
  Future<void> addCobro(Cobro cobro);
  Future<void> deleteCobro(String id);
  Future<void> marcarCierreDelDia(DateTime fecha);

  // Aggregated queries
  Future<double> getTotalPorDia(DateTime fecha);
  Future<Map<String, double>> getTotalPorSastre(DateTime inicio, DateTime fin);
  Future<double> getTotalHistorico();
  Future<double> getComisionesAcumuladas(DateTime inicio, DateTime fin);
}
