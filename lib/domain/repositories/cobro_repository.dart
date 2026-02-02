import '../entities/cobro.dart';

abstract class CobroRepository {
  Future<List<Cobro>> getCobrosDelDia(DateTime fecha);
  Future<List<Cobro>> getAllCobros();
  Future<void> addCobro(Cobro cobro);
  Future<void> deleteCobro(String id);
  Future<void> clearCobrosDelDia(DateTime fecha);
}
