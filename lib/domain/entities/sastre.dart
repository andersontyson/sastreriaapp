class Sastre {
  final String id;
  final String nombre;
  final bool esDueno;
  final bool estaActivo;
  final DateTime createdAt;
  final double? comisionFija;

  Sastre({
    required this.id,
    required this.nombre,
    required this.esDueno,
    this.estaActivo = true,
    required this.createdAt,
    this.comisionFija,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'esDueno': esDueno ? 1 : 0,
      'estaActivo': estaActivo ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'comisionFija': comisionFija,
    };
  }

  factory Sastre.fromMap(Map<String, dynamic> map) {
    return Sastre(
      id: map['id'],
      nombre: map['nombre'],
      esDueno: map['esDueno'] == 1,
      estaActivo: map['estaActivo'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      comisionFija: (map['comisionFija'] as num?)?.toDouble(),
    );
  }
}
