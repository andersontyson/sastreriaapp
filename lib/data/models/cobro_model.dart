import '../../domain/entities/cobro.dart';

class CobroModel extends Cobro {
  CobroModel({
    required super.id,
    required super.sastreId,
    required super.monto,
    super.cliente,
    super.prenda,
    required super.fechaHora,
    required super.comisionMonto,
    required super.netoSastre,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sastreId': sastreId,
      'monto': monto,
      'cliente': cliente,
      'prenda': prenda,
      'fechaHora': fechaHora.toIso8601String(),
      'comisionMonto': comisionMonto,
      'netoSastre': netoSastre,
    };
  }

  factory CobroModel.fromMap(Map<String, dynamic> map) {
    return CobroModel(
      id: map['id'],
      sastreId: map['sastreId'],
      monto: (map['monto'] as num).toDouble(),
      cliente: map['cliente'],
      prenda: map['prenda'],
      fechaHora: DateTime.parse(map['fechaHora']),
      comisionMonto: (map['comisionMonto'] as num).toDouble(),
      netoSastre: (map['netoSastre'] as num).toDouble(),
    );
  }
}
