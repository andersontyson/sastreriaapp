class Sastre {
  final String id;
  final String nombre;
  final bool esDueno;
  final double? comisionFija;
  final bool estaActivo;

  Sastre({
    required this.id,
    required this.nombre,
    required this.esDueno,
    this.comisionFija,
    this.estaActivo = true,
  });
}
