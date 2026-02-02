class Cobro {
  final String id;
  final String sastreId;
  final double monto;
  final String? cliente;
  final String? prenda;
  final DateTime fechaHora;
  final double comisionMonto;
  final double netoSastre;

  Cobro({
    required this.id,
    required this.sastreId,
    required this.monto,
    this.cliente,
    this.prenda,
    required this.fechaHora,
    required this.comisionMonto,
    required this.netoSastre,
  });
}
