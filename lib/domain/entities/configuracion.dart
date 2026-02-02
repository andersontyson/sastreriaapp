class Configuracion {
  final int id;
  final String nombreNegocio;
  final double comisionGeneral;
  final bool isActivated;
  final DateTime? activationDate;
  final String? activationCode;

  Configuracion({
    this.id = 1,
    required this.nombreNegocio,
    required this.comisionGeneral,
    this.isActivated = false,
    this.activationDate,
    this.activationCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombreNegocio': nombreNegocio,
      'comisionGeneral': comisionGeneral,
      'isActivated': isActivated ? 1 : 0,
      'activationDate': activationDate?.toIso8601String(),
      'activationCode': activationCode,
    };
  }

  factory Configuracion.fromMap(Map<String, dynamic> map) {
    return Configuracion(
      id: map['id'] ?? 1,
      nombreNegocio: map['nombreNegocio'] ?? '',
      comisionGeneral: (map['comisionGeneral'] as num?)?.toDouble() ?? 0.0,
      isActivated: map['isActivated'] == 1,
      activationDate: map['activationDate'] != null
          ? DateTime.parse(map['activationDate'])
          : null,
      activationCode: map['activationCode'],
    );
  }

  Configuracion copyWith({
    String? nombreNegocio,
    double? comisionGeneral,
    bool? isActivated,
    DateTime? activationDate,
    String? activationCode,
  }) {
    return Configuracion(
      id: this.id,
      nombreNegocio: nombreNegocio ?? this.nombreNegocio,
      comisionGeneral: comisionGeneral ?? this.comisionGeneral,
      isActivated: isActivated ?? this.isActivated,
      activationDate: activationDate ?? this.activationDate,
      activationCode: activationCode ?? this.activationCode,
    );
  }
}
