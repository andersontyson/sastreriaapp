import '../../domain/entities/configuracion.dart';

class ConfigModel extends Configuracion {
  ConfigModel({
    required super.nombreNegocio,
    required super.comisionGeneral,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombreNegocio': nombreNegocio,
      'comisionGeneral': comisionGeneral,
    };
  }

  factory ConfigModel.fromMap(Map<String, dynamic> map) {
    return ConfigModel(
      nombreNegocio: map['nombreNegocio'] ?? 'Sastrería',
      comisionGeneral: (map['comisionGeneral'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
