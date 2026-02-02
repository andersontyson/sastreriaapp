import '../entities/configuracion.dart';

abstract class ConfigRepository {
  Future<Configuracion?> getConfig();
  Future<void> saveConfig(Configuracion config);
}
