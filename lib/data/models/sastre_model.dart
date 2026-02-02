import '../../domain/entities/sastre.dart';

class SastreModel extends Sastre {
  SastreModel({
    required super.id,
    required super.nombre,
    required super.esDueno,
    super.comisionFija,
    super.estaActivo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'esDueno': esDueno ? 1 : 0,
      'comisionFija': comisionFija,
      'estaActivo': estaActivo ? 1 : 0,
    };
  }

  factory SastreModel.fromMap(Map<String, dynamic> map) {
    return SastreModel(
      id: map['id'],
      nombre: map['nombre'],
      esDueno: map['esDueno'] == 1,
      comisionFija: (map['comisionFija'] as num?)?.toDouble(),
      estaActivo: map['estaActivo'] == 1,
    );
  }
}
