class Cobro {
  final String id;
  final String sastreId;
  final double montoTotal;
  final double comisionPorcentaje;
  final double comisionMonto;
  final double netoSastre;
  final DateTime fecha;
  final bool esCierre;
  final String? cliente;
  final String? prenda;

  Cobro({
    required this.id,
    required this.sastreId,
    required this.montoTotal,
    required this.comisionPorcentaje,
    required this.comisionMonto,
    required this.netoSastre,
    required this.fecha,
    this.esCierre = false,
    this.cliente,
    this.prenda,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sastreId': sastreId,
      'montoTotal': montoTotal,
      'comisionPorcentaje': comisionPorcentaje,
      'comisionMonto': comisionMonto,
      'netoSastre': netoSastre,
      'fecha': fecha.toIso8601String(),
      'esCierre': esCierre ? 1 : 0,
      'cliente': cliente,
      'prenda': prenda,
    };
  }

  factory Cobro.fromMap(Map<String, dynamic> map) {
    return Cobro(
      id: map['id'],
      sastreId: map['sastreId'],
      montoTotal: (map['montoTotal'] as num).toDouble(),
      comisionPorcentaje: (map['comisionPorcentaje'] as num).toDouble(),
      comisionMonto: (map['comisionMonto'] as num).toDouble(),
      netoSastre: (map['netoSastre'] as num).toDouble(),
      fecha: DateTime.parse(map['fecha']),
      esCierre: map['esCierre'] == 1,
      cliente: map['cliente'],
      prenda: map['prenda'],
    );
  }
}
