import '../entities/sastre.dart';

abstract class SastreRepository {
  Future<List<Sastre>> getSastres();
  Future<void> addSastre(Sastre sastre);
  Future<void> updateSastre(Sastre sastre);
  Future<void> deleteSastre(String id);
}
