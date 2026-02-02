class Configuracion {
  final int id;
  final String nombreNegocio;
  final double comisionGeneral;

  Configuracion({
    this.id = 1,
    required this.nombreNegocio,
    required this.comisionGeneral,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombreNegocio': nombreNegocio,
      'comisionGeneral': comisionGeneral,
    };
  }

  factory Configuracion.fromMap(Map<String, dynamic> map) {
    return Configuracion(
      id: map['id'] ?? 1,
      nombreNegocio: map['nombreNegocio'],
      comisionGeneral: (map['comisionGeneral'] as num).toDouble(),
    );
  }
}
